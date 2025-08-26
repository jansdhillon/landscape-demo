resource "local_file" "example" {
  content  = var.hello
  filename = "output.txt"
}
