package config

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/hashicorp/hcl/v2/hclwrite"
	"github.com/zclconf/go-cty/cty"
	"github.com/zclconf/go-cty/cty/gocty"
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

	terraformDir := filepath.Join(dir, "")

	return terraformDir, nil
}

func TfVarsPath() (string, error) {
	tfDir, err := TerraformDirectory()
	if err != nil {
		return "", err
	}
	varsPath := filepath.Join(tfDir, "terraform.tfvars")

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
		evalContext := &hcl.EvalContext{
			Variables: vars,
		}
		val, diags := attr.Expr.Value(evalContext)
		if diags.HasErrors() {
			return nil, fmt.Errorf("value errors for %s: %s", name, diags.Error())
		}
		vars[name] = val
	}

	return vars, nil
}

func WriteHCLTfVars(filename string, vars map[string]cty.Value) error {
	f := hclwrite.NewEmptyFile()
	rootBody := f.Body()

	var names []string
	for name := range vars {
		names = append(names, name)
	}
	sort.Strings(names)

	for _, name := range names {
		entry := vars[name]

		if entry.IsNull() {
			continue
		}

		tokens := hclwrite.TokensForValue(entry)
		rootBody.SetAttributeRaw(name, tokens)

		rootBody.AppendNewline()
	}

	return os.WriteFile(filename, f.Bytes(), 0644)
}

type Module interface {
	GetModuleValue(context.Context, string) (cty.Value, error)
	SetModuleValue(context.Context, string, any) (cty.Value, error)
}

type LandscapeDemoModule struct {
	TfVarsPath   string
	TerraformDir string
}

func (m *LandscapeDemoModule) SetModuleValue(ctx context.Context, name string, value any) (cty.Value, error) {
	currentVars, err := ParseHCLTfvars(m.TfVarsPath)
	if err != nil {
		fmt.Printf("error parsing HCL tfvars: %v", err)
		return cty.Value{}, err
	}

	ctyVal, err := gocty.ToCtyValue(value, cty.DynamicPseudoType)
	if err != nil {
		return cty.Value{}, fmt.Errorf("failed to convert value to cty: %w", err)
	}

	currentVars[name] = ctyVal

	err = WriteHCLTfVars(m.TfVarsPath, currentVars)
	if err != nil {
		return cty.Value{}, fmt.Errorf("error writing tfvars: %w", err)
	}

	return ctyVal, nil

}

func (m *LandscapeDemoModule) GetModuleValue(ctx context.Context, name string) (cty.Value, error) {
	currentVars, err := ParseHCLTfvars(m.TfVarsPath)
	if err != nil {
		return cty.Value{}, fmt.Errorf("error parsing tfvars: %v", err)
	}

	entry, exists := currentVars[name]
	if !exists {
		return cty.Value{}, fmt.Errorf("variable %s not found", name)
	}

	return entry, nil
}
