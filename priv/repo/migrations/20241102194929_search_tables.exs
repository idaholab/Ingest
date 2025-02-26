defmodule Ingest.Repo.Migrations.SearchTables do
  use Ecto.Migration

  def change do
    execute "CREATE VIRTUAL TABLE projects_search USING fts5(id ,name, description, tokenize='trigram', content='projects', content_rowid='rowid');"

    execute "CREATE VIRTUAL TABLE templates_search USING fts5(id ,name, description, tokenize='trigram', content='templates', content_rowid='rowid');"

    execute "CREATE VIRTUAL TABLE destinations_search USING fts5(id ,name, tokenize='trigram', content='destinations', content_rowid='rowid');"

    execute "CREATE VIRTUAL TABLE requests_search USING fts5(id,name, description, tokenize='trigram', content='requests', content_rowid='rowid');"

    execute "CREATE TRIGGER t1_ai_projects_search AFTER INSERT ON projects BEGIN
  INSERT INTO projects_search(rowid,id, name, description) VALUES (new.rowid, new.id, new.name, new.description);
END;"
    execute "CREATE TRIGGER t1_ad_projects AFTER DELETE ON projects BEGIN
  INSERT INTO projects_search(projects_search, rowid,id, name, description) VALUES('delete', old.rowid, old.id, old.name, old.description);
END;"
    execute "CREATE TRIGGER t1_au_projects AFTER UPDATE ON projects BEGIN
  INSERT INTO projects_search(projects_search, rowid,id, name, description) VALUES('delete', old.rowid, old.id, old.name, old.description);
  INSERT INTO projects_search(rowid,id, name, description) VALUES (new.rowid, new.id, new.name, new.description);
END;"

    execute "CREATE TRIGGER t1_ai_templates_search AFTER INSERT ON templates BEGIN
INSERT INTO templates_search(rowid,id, name, description) VALUES (new.rowid, new.id, new.name, new.description);
END;"
    execute "CREATE TRIGGER t1_ad_templates AFTER DELETE ON templates BEGIN
INSERT INTO templates_search(templates_search, rowid,id, name, description) VALUES('delete', old.rowid, old.id, old.name, old.description);
END;"
    execute "CREATE TRIGGER t1_au_templates AFTER UPDATE ON templates BEGIN
INSERT INTO templates_search(templates_search, rowid,id, name, description) VALUES('delete', old.rowid, old.id, old.name, old.description);
INSERT INTO templates_search(rowid,id, name, description) VALUES (new.rowid, new.id, new.name, new.description);
END;"

    execute "CREATE TRIGGER t1_ai_requests_search AFTER INSERT ON requests BEGIN
INSERT INTO requests_search(rowid,id, name, description) VALUES (new.rowid, new.id, new.name, new.description);
END;"
    execute "CREATE TRIGGER t1_ad_requests AFTER DELETE ON requests BEGIN
INSERT INTO requests_search(requests_search, rowid,id, name, description) VALUES('delete', old.rowid, old.id, old.name, old.description);
END;"
    execute "CREATE TRIGGER t1_au_requests AFTER UPDATE ON requests BEGIN
INSERT INTO requests_search(requests_search, rowid,id, name, description) VALUES('delete', old.rowid, old.id, old.name, old.description);
INSERT INTO requests_search(rowid,id, name, description) VALUES (new.rowid, new.id, new.name, new.description);
END;"

    execute "CREATE TRIGGER t1_ai_destinations_search AFTER INSERT ON destinations BEGIN
INSERT INTO destinations_search(rowid,id, name) VALUES (new.rowid, new.id, new.name);
END;"
    execute "CREATE TRIGGER t1_ad_destinations AFTER DELETE ON destinations BEGIN
INSERT INTO destinations_search(destinations_search, rowid,id, name) VALUES('delete', old.rowid, old.id, old.name);
END;"
    execute "CREATE TRIGGER t1_au_destinations AFTER UPDATE ON destinations BEGIN
INSERT INTO destinations_search(destinations_search, rowid,id, name) VALUES('delete', old.rowid, old.id, old.name);
INSERT INTO destinations_search(rowid,id, name) VALUES (new.rowid, new.id, new.name);
END;"
  end
end
