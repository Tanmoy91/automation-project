package main


import (
"fmt"
"os"
"os/exec"
)


func run(name string, args ...string) error {
cmd := exec.Command(name, args...)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
return cmd.Run()
}


func main() {
fmt.Println("=== Real Environment Automation (Local k3s) ===")


// terraform init
fmt.Println("\n>> terraform init")
if err := run("terraform", "-chdir=../terraform", "init"); err != nil {
panic(err)
}


// terraform apply
fmt.Println("\n>> terraform apply")
if err := run("terraform", "-chdir=../terraform", "apply", "-auto-approve"); err != nil {
panic(err)
}


fmt.Println("\n✅ Done. Visit: Nginx http://127.0.0.1:30081 | Grafana http://127.0.0.1:30080 | Prometheus http://127.0.0.1:30900")
}