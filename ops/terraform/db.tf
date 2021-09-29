# resource "google_sql_database_instance" "instance" {
#   name   = "cloudrun-sql"
#   region = "us-east1"
#   settings {
#     tier = "db-f1-micro"
#   }

#   deletion_protection  = "false"
# }