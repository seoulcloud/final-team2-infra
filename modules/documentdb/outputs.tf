output "docdb_cluster_endpoint" {
  description = "The endpoint of the DocumentDB cluster"
  value       = aws_docdb_cluster.this.endpoint
}

output "docdb_cluster_reader_endpoint" {
  description = "The reader endpoint of the DocumentDB cluster"
  value       = aws_docdb_cluster.this.reader_endpoint
}