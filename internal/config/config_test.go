package config

import (
	"context"
	"os"
	"path/filepath"
	"testing"

	"github.com/zclconf/go-cty/cty/gocty"
)

func createTestTfvars(t *testing.T, content string) (string, func()) {
	tmpDir := t.TempDir()
	tfvarsPath := filepath.Join(tmpDir, "terraform.tfvars")

	if err := os.WriteFile(tfvarsPath, []byte(content), 0644); err != nil {
		t.Fatalf("failed to create test tfvars file: %v", err)
	}

	cleanup := func() {}

	return tfvarsPath, cleanup
}

func TestGetModuleVariable(t *testing.T) {
	content := `
test = "hello"
number_val = 42
list_val = ["a", "b", "c"]
`

	tfvarsPath, cleanup := createTestTfvars(t, content)
	defer cleanup()

	m := LandscapeDemoModule{
		TfVarsPath:   tfvarsPath,
		TerraformDir: filepath.Dir(tfvarsPath),
	}

	val, err := m.GetModuleValue(context.Background(), "test")
	if err != nil {
		t.Fatalf("failed to get value: %v", err)
	}

	var got string
	err = gocty.FromCtyValue(val, &got)
	if err != nil {
		t.Fatalf("failed to convert: %v", err)
	}

	if got != "hello" {
		t.Errorf("wanted: hello, got: %s", got)
	}
}
