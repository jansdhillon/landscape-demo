package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec" // For running the bash script
	"path/filepath"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
)

func main() {
	ctx := context.Background()

	// --- 1. Install Terraform CLI (if not already present) ---
	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion("1.12.0")), // Use a specific, stable version
	}

	execPath, err := installer.Install(ctx)
	if err != nil {
		log.Fatalf("Error installing Terraform: %s", err)
	}

	// Determine the base working directory of your project
	// This assumes your Go executable is run from the root of your project
	// or you define the absolute path.
	baseWorkingDir, err := os.Getwd() // Or provide absolute path like "/path/to/your/project"
	if err != nil {
		log.Fatalf("Error getting current working directory: %s", err)
	}

	// --- 2. Deploy Terraform Module 1 ---
	fmt.Println("--- Deploying Terraform Module 1 ---")
	module1Dir := filepath.Join(baseWorkingDir, "terraform-module-1")

	tf1, err := tfexec.NewTerraform(module1Dir, execPath)
	if err != nil {
		log.Fatalf("Error creating Terraform instance for Module 1: %s", err)
	}

	// Optional: Set a logger if you want to see Terraform's output
	tf1.SetLogger(log.New(os.Stdout, "", log.LstdFlags))

	err = tf1.Init(ctx, tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("Error running Init for Module 1: %s", err)
	}

	err = tf1.Apply(ctx)
	if err != nil {
		log.Fatalf("Error running Apply for Module 1: %s", err)
	}
	fmt.Println("Module 1 deployed successfully.")

	// --- 3. Run the Bash Script ---
	fmt.Println("--- Running Bash Script ---")
	scriptPath := filepath.Join(baseWorkingDir, "scripts", "my-bash-script.sh")

	// Ensure the script is executable
	if err := os.Chmod(scriptPath, 0755); err != nil {
		log.Fatalf("Error setting execute permissions on script: %s", err)
	}

	cmd := exec.Command(scriptPath)
	cmd.Stdout = os.Stdout // Pipe script output to Go application's stdout
	cmd.Stderr = os.Stderr // Pipe script errors to Go application's stderr
	if err := cmd.Run(); err != nil {
		log.Fatalf("Error executing bash script: %s", err)
	}
	fmt.Println("Bash script executed successfully.")

	// --- 4. Deploy Terraform Module 2 ---
	fmt.Println("--- Deploying Terraform Module 2 ---")
	module2Dir := filepath.Join(baseWorkingDir, "terraform-module-2")

	tf2, err := tfexec.NewTerraform(module2Dir, execPath)
	if err != nil {
		log.Fatalf("Error creating Terraform instance for Module 2: %s", err)
	}

	tf2.SetLogger(log.New(os.Stdout, "", log.LstdFlags)) // Again, for output

	err = tf2.Init(ctx, tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("Error running Init for Module 2: %s", err)
	}

	err = tf2.Apply(ctx)
	if err != nil {
		log.Fatalf("Error running Apply for Module 2: %s", err)
	}
	fmt.Println("Module 2 deployed successfully.")

	fmt.Println("All deployments and script execution complete!")
}
