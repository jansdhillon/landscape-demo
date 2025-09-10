package config

import (
	"os"
	"path/filepath"
	"testing"
)

func createTestTfvars(t *testing.T, content string) func() {
	tmpDir := t.TempDir()
	tfvarsPath := filepath.Join(tmpDir, TfVarsJsonFileName)

	if err := os.WriteFile(tfvarsPath, []byte(content), 0644); err != nil {
		t.Fatalf("failed to create test tfvars file: %v", err)
	}

	originalDir, err := os.Getwd()
	if err != nil {
		t.Fatalf("failed to get current dir: %v", err)
	}

	if err := os.Chdir(tmpDir); err != nil {
		t.Fatalf("failed to change dir: %v", err)
	}

	return func() {
		os.Chdir(originalDir)
	}
}

func TestParseTfJsonVars(t *testing.T) {
	tests := []struct {
		name    string
		content string
		want    *Config
		wantErr bool
	}{
		{
			name: "valid config",
			content: `{
				"workspace_name": "test-workspace",
				"domain": "example.com",
				"smtp_port": 587,
				"min_install": true
			}`,
			want: &Config{
				WorkspaceName: "test-workspace",
				Domain:        "example.com",
				SMTPPort:      587,
				MinInstall:    true,
			},
		},
		{
			name:    "empty config",
			content: `{}`,
			want:    &Config{},
		},
		{
			name:    "invalid json",
			content: `{"invalid": json}`,
			wantErr: true,
		},
		{
			name:    "empty content",
			content: "",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tmpFile, err := os.CreateTemp("", "test-*.json")
			if err != nil {
				t.Fatal(err)
			}
			defer os.Remove(tmpFile.Name())

			tmpFile.WriteString(tt.content)
			tmpFile.Close()

			got, err := ParseTfJsonVars(tmpFile.Name())
			if (err != nil) != tt.wantErr {
				t.Errorf("ParseTfJsonVars() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && !configEqual(got, tt.want) {
				t.Errorf("ParseTfJsonVars() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestTfVarsPath(t *testing.T) {
	tests := []struct {
		name       string
		createFile bool
		wantErr    bool
	}{
		{
			name:       "file exists",
			createFile: true,
			wantErr:    false,
		},
		{
			name:       "file not exists",
			createFile: false,
			wantErr:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var cleanup func()
			if tt.createFile {
				cleanup = createTestTfvars(t, `{"test": "value"}`)
				defer cleanup()
			} else {
				tmpDir := t.TempDir()
				originalDir, _ := os.Getwd()
				os.Chdir(tmpDir)
				defer os.Chdir(originalDir)
			}

			_, err := TfVarsPath()
			if (err != nil) != tt.wantErr {
				t.Errorf("TfVarsPath() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func configEqual(a, b *Config) bool {
	return a.WorkspaceName == b.WorkspaceName &&
		a.Domain == b.Domain &&
		a.SMTPPort == b.SMTPPort &&
		a.MinInstall == b.MinInstall &&
		a.PathToSSHKey == b.PathToSSHKey &&
		a.ProToken == b.ProToken &&
		a.Hostname == b.Hostname &&
		a.AdminName == b.AdminName &&
		a.AdminEmail == b.AdminEmail &&
		a.AdminPassword == b.AdminPassword
}
