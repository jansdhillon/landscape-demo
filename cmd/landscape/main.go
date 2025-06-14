package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
)

const (
	TerraformVersion = "1.12.0"
)

func main() {
	ctx := context.Background()

	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion(TerraformVersion)),
	}

	execPath, err := installer.Install(ctx)
	if err != nil {
		log.Fatalf("Error installing Terraform: %s", err)
	}

	baseWorkingDir, err := os.Getwd()
	if err != nil {
		log.Fatalf("Error getting current working directory: %s", err)
	}

	terraformDir := filepath.Join(baseWorkingDir, "terraform")

	tf, err := tfexec.NewTerraform(terraformDir, execPath)
	if err != nil {
		log.Fatalf("Error creating Terraform instance: %s", err)
	}

	tf.SetLogger(log.New(os.Stdout, "", log.LstdFlags))

	err = tf.Init(ctx, tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("Error running Init: %s", err)
	}

	fmt.Println("Deploying Terraform modules...")

	planfile := filepath.Join(terraformDir, "planfile")

	changed, err := tf.Plan(ctx, tfexec.Out(planfile))

	if err != nil {
		log.Fatalf("Error running Plan: %s", err)
	}

	log.Printf("Changed: %t", changed)

	plan, err := tf.ShowPlanFile(ctx, planfile)
	if err != nil {
		log.Fatalf("Error reading planfile: %s", err)
	}

	log.Printf("Plan has %d resource changes", len(plan.ResourceChanges))

	planJSON, err := json.MarshalIndent(plan, "", "  ")
	if err != nil {
		log.Fatalf("Error marshaling plan to JSON: %s", err)
	}
	log.Printf("Plan JSON: %s", string(planJSON))

	planDir := filepath.Dir(planfile)
	jsonFile := filepath.Join(planDir, "plan.json")
	writeErr := os.WriteFile(jsonFile, planJSON, 0644)
	if writeErr != nil {
		log.Fatalf("Error writing plan JSON file: %s", writeErr)
	}

	// Deploy Landscape Server

	// Get outputs (HAProxy IP, etc.)

}
