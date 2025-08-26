package config

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/hashicorp/hcl/v2/hclwrite"
	"github.com/zclconf/go-cty/cty"
)

const (
	TerraformVersion = "1.13.0"
	TfVarsFileName   = "terraform.tfvars"
)

func TerraformDirectory() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	return dir + "/terraform", nil
}

func TfVarsPath(workingDirectory string) (string, error) {
	varsPath := filepath.Join(workingDirectory, TfVarsFileName)

	if _, err := os.Stat(varsPath); err != nil {
		if os.IsNotExist(err) {
			return "", fmt.Errorf("tfvars file not found: %s", varsPath)
		}
		return "", err
	}

	return varsPath, nil
}

func ParseHCLTfvars(filename string) (map[string]cty.Value, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	file, diags := hclsyntax.ParseConfig(content, filename, hcl.Pos{Line: 1, Column: 1})
	if diags.HasErrors() {
		return nil, fmt.Errorf("parse errors: %s", diags.Error())
	}

	vars := make(map[string]cty.Value)
	attrs, diags := file.Body.JustAttributes()
	if diags.HasErrors() {
		return nil, fmt.Errorf("attribute errors: %s", diags.Error())
	}

	for name, attr := range attrs {
		val, diags := attr.Expr.Value(nil)
		if diags.HasErrors() {
			return nil, fmt.Errorf("value errors: %s", diags.Error())
		}
		vars[name] = val
	}

	return vars, nil
}

func WriteHCLTfVars(filename string, vars map[string]cty.Value) error {
	f := hclwrite.NewEmptyFile()
	rootBody := f.Body()

	for name, val := range vars {
		rootBody.SetAttributeValue(name, val)
	}

	return os.WriteFile(filename, f.Bytes(), 0644)
}
