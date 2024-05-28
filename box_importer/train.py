import os, sys, argparse
import evaluate
import mlflow
import mlflow.pytorch

import torch
import pandas as pd
import numpy as np

from sklearn.model_selection import train_test_split
from torch.utils.data import DataLoader, Dataset
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from transformers import TrainingArguments, Trainer, DataCollatorWithPadding#, BitsAndBytesConfig
from accelerate import Accelerator, DataLoaderConfiguration

###--------------------------------------------------------------###
# Custom Dataset Class
class TextClassificationDataset(Dataset):
    def __init__(self, texts, labels, label2id, tokenizer, device, max_length):
        self.texts = texts
        self.labels = labels
        self.label2id = label2id
        self.tokenizer = tokenizer
        self.device = device
        self.max_length = max_length
    def __len__(self):
        return len(self.texts)
    def __getitem__(self, idx):
        text = self.texts[idx]
        label = self.labels[idx]
        encoding = self.tokenizer(text, return_tensors='pt', max_length=self.max_length, padding='max_length', truncation=True)
        return {'input_ids': encoding['input_ids'].squeeze().to(self.device),
                'attention_mask': encoding['attention_mask'].squeeze().to(self.device),
                'label': torch.tensor(self.label2id[label]).squeeze().to(self.device)}


###--------------------------------------------------------------###
# Function to load data - replace with actual implementation
def load_data(data_file):
    assert os.path.isfile(data_file), f"{data_file} does not exist!"

    df = pd.DataFrame()
    if data_file.endswith ('.csv'):
        df = pd.read_csv(data_file)
    elif data_file.endswith ('.xlsx'):
        df = pd.read_excel(data_file)
    elif data_file.endswith('.json') or data_file.endswith('.JSON'):
        df = pd.read_json(data_file)
    elif data_file.endswith('.pkl'):
        df = pd.read_pickle(data_file)
    else:
        raise ValueError(f"Unsupported file format: {data_file}. Supported formats are: .csv, .xlsx, .json, .JSON, .pkl")

    assert not df.empty, f"No data from raw input file!"
    assert 'text' in df.columns and 'label' in df.columns, f"There are no 'text' and 'label' columns in file!"

    print(f"Loaded data shape: {df.shape}")
    df = df.dropna().drop_duplicates().reset_index(drop=True)
    print(f"Dropped duplicate shape: {df.shape}")

    id2label = dict(enumerate(df['label'].unique()))
    label2id = {label: label_id for label_id, label in id2label.items()}

    return id2label, label2id, df

# Function to create train and test datasets - replace with actual implementation
def create_train_test_datasets(df, test_size=0.2, stratify=False):
    if stratify:
        value_counts = df.value_counts('label').reset_index()
        exclude_labels = value_counts[value_counts['count']<2]['label'].tolist()
        print(f"Dropping data for labels with only 1 occurrence for stratified train_test_split...")
        print(f"Dropped {len(exclude_labels)} out of {len(value_counts)} labels: ", exclude_labels)
        df = df[~df['label'].isin(exclude_labels)]

    texts, labels = df['text'].tolist(), df['label'].tolist()
    stratify_by = labels if stratify else None

    return train_test_split(texts, labels, test_size=test_size, stratify=stratify_by, random_state=42)



###--------------------------------------------------------------###
# Function to compute metrics
def compute_metrics(eval_pred):
    accuracy = evaluate.load("accuracy")

#     predictions, labels = eval_pred
#     predictions = np.argmax(predictions, axis=1)

    logits, labels = eval_pred
    if isinstance(logits, tuple):  # For models like T5 that return multiple outputs
        logits = logits[0]
    predictions = np.argmax(logits, axis=-1)
    return accuracy.compute(predictions=predictions, references=labels)

###--------------------------------------------------------------###
# Evaluate function to predict from user input
def predict_tact_tech(text, model, tokenizer, device, accelerator, max_length=256):
    encoding = tokenizer(
        text,
        return_tensors='pt',
        max_length=max_length,
        padding='max_length',
        truncation=True
    )

    encoding = {k: v.to(accelerator.device) for k, v in encoding.items()}

    model.eval()
    with torch.no_grad():
        outputs = model(**encoding)
        logits = outputs.logits

        if isinstance(logits, tuple):  # For models like T5 that return multiple outputs
            logits = logits[0]

        predictions = torch.argmax(logits, dim=-1).cpu().numpy()

    id2label = model.config.id2label
    predicted_labels = [id2label[pred] for pred in predictions]
    return predicted_labels
###--------------------------------------------------------------###


# Main function
def main(args):

    accelerator = Accelerator()
    device = torch.device('cuda') if torch.cuda.is_available() else 'cpu'
    print(f"Using device: {device}")

    # Load data
    id2label, label2id, df = load_data("/home/swinjo/training/data/raw_input.csv")  # Replace with your data file
    train_texts, val_texts, train_labels, val_labels = create_train_test_datasets(df, stratify=False)

    # Model and tokenizer initialization
    model_id = "roberta-base"

    ###--------------------------------------------------------------###
    try:
        model = AutoModelForSequenceClassification.from_pretrained(model_id, num_labels=len(id2label),
                                                                   id2label=id2label, label2id=label2id,
                                                                   device_map = 'auto')
    except ValueError as e:
        # If the device_map parameter is not supported, load the model without it
        print(f"Warning: {e}. Loading model without 'device_map'.")

        model = AutoModelForSequenceClassification.from_pretrained(model_id, num_labels=len(id2label),
                                                                   id2label=id2label, label2id=label2id).to(device)

    tokenizer = AutoTokenizer.from_pretrained(model_id)
    ###--------------------------------------------------------------###
    # Prepare datasets and data collator
    train_dataset = TextClassificationDataset(train_texts, train_labels, label2id, tokenizer, device, args.token_max_length)
    val_dataset = TextClassificationDataset(val_texts, val_labels, label2id, tokenizer, device, args.token_max_length)
    data_collator = DataCollatorWithPadding(tokenizer=tokenizer, padding='longest')

    # Training arguments
    training_args = TrainingArguments(
        output_dir="/home/swinjo/training/output/",
        overwrite_output_dir=True,
        learning_rate = args.lr,
        per_device_train_batch_size = args.train_batch_size,
        per_device_eval_batch_size = args.eval_batch_size,
        num_train_epochs = args.epochs,
        weight_decay = 0.01,
        evaluation_strategy = "epoch",
        save_strategy = "epoch",
        load_best_model_at_end = True,
        save_total_limit = 1,
        metric_for_best_model = "accuracy",
        greater_is_better = True,
        push_to_hub = False
    )

    # Initialize Trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset,
        tokenizer=tokenizer,
        data_collator=data_collator,
        compute_metrics=compute_metrics,
    )

    # Prepare everything with accelerator
    model, optimizer, train_dataloader, eval_dataloader = accelerator.prepare(
        model,
        trainer.create_optimizer(),
        trainer.get_train_dataloader(),
        trainer.get_eval_dataloader()
    )

#     Disable parallelism warning
    os.environ["TOKENIZERS_PARALLELISM"] = "false"

    mlflow.set_tracking_uri("https://mlflow-dev.de.inl.gov/")

    ###--------------------------------------------------------------###
    # Set up MLFlow experiment
    mlflow.set_experiment("HF-Text-Classification")

    # Initialize MLFlow run
    with mlflow.start_run(run_name=model_id):
        # Log parameters
        mlflow.log_params({
            "model_id": model_id,
            "learning_rate": args.lr,
            "epochs": args.epochs,
            "train_batch_size": args.train_batch_size,
            "eval_batch_size": args.eval_batch_size,
            "token_max_length": args.token_max_length,
        })

        # logs the training script and input data
        mlflow.log_artifact("/home/swinjo/training/data/raw_input.csv", artifact_path='input_data')

        # Train the model
        trainer.train()

        # Evaluate the model
        eval_metrics = trainer.evaluate()

        # Log metrics
        mlflow.log_metrics(eval_metrics)

        # Log the model
        mlflow.pytorch.log_model(model, f"{model_id}_model")

    ###--------------------------------------------------------------###
    # EVALUATION:
    # Test  prediction
    test_text = "Proprietary Software on Transient Cyber Asset"
    technique = predict_tact_tech(test_text, model, tokenizer, device, accelerator)
    print("Proprietary Software on Transient Cyber Asset")
    print(f"Predicted Tactic Technique: {technique}")

    # Test  prediction
    test_text = "\nNear Operational Site: Near Radio Repeater Station: Vehicle Owned by Former Employee"
    technique = predict_tact_tech(test_text, model, tokenizer, device, accelerator)
    print(test_text)
    print(f"Predicted Tactic Technique: {technique}")

if __name__ == "__main__":

    # Create an ArgumentParser object
    parser = argparse.ArgumentParser(description="Arguments for finetuning HF text classifiers")

    # Add required argument
    # parser.add_argument('--data_path', type=str, required=True, help='Path to accessing input data')
    # parser.add_argument('--pretrained_id', type=str, required=True, help='Path to or model_id for the pretrained model')
    # parser.add_argument('--save_path', type=str, required=True, help='Path for saving the finetuned model')


    # Add optional arguments
    parser.add_argument('--lr', type=float, default=2e-5, help='Learning rate for training (default: 2e-5)')
    parser.add_argument('--epochs', type=int, default=15, help='Number of training epochs (default: 10)')
    parser.add_argument('--train_batch_size', type=int, default=32, help='Batch size for training (default: 32)')
    parser.add_argument('--eval_batch_size', type=int, default=16, help='Batch size for evaluating (default: 16)')
    parser.add_argument('--token_max_length', type=int, default=256, help='Tokenizer max_length for training (default: 256)')


    # Parse arguments
    args = parser.parse_args()

    # check input data file path
    #assert os.path.isfile(args.data_path), f"{args.data_path} is invalid!"

    # check if the specified pretrained-model-id/path is valid
    #supported_pretrained_model_names = ['roberta-base', 'roberta-large', 'bert-base-uncased',
    #                                    'distilbert-base-uncased', 'albert-base-v2', 't5-base',
    #                                    'google/electra-base-discriminator'] # not working: 'xlnet-base-cased',

    #is_supported_pretrained_id = args.pretrained_id in supported_pretrained_model_names
    #is_valid_model_path = os.path.exists(args.pretrained_id)
    #if not (is_supported_pretrained_id or is_valid_model_path):
    #    raise ValueError(f"pretrained_id: '{args.pretrained_id}' is neither a supported HF model_id nor a valid model path!")

    ###-------------------------------------###
    main(args)
