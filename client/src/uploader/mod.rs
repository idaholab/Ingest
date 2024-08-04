use std::sync::Arc;
use object_store::ObjectStore;

pub struct Uploader {
    object_store: Arc<dyn ObjectStore>
}

impl Uploader {
}
