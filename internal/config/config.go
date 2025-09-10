package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

const (
	TerraformVersion   = "1.13.0"
	TfVarsJsonFileName = "terraform.tfvars.json"
)

type Config struct {
	WorkspaceName           string `json:"workspace_name"`
	PathToSSHKey            string `json:"path_to_ssh_key"`
	ProToken                string `json:"pro_token"`
	Domain                  string `json:"domain"`
	Hostname                string `json:"hostname"`
	PathToSSLCert           string `json:"path_to_ssl_cert"`
	PathToSSLKey            string `json:"path_to_ssl_key"`
	B64SSLCert              string `json:"b64_ssl_cert"`
	B64SSLKey               string `json:"b64_ssl_key"`
	AdminName               string `json:"admin_name"`
	AdminEmail              string `json:"admin_email"`
	AdminPassword           string `json:"admin_password"`
	MinInstall              bool   `json:"min_install"`
	LandscapePPA            string `json:"landscape_ppa"`
	RegistrationKey         string `json:"registration_key"`
	LandscapeServerBase     string `json:"landscape_server_base"`
	LandscapeServerChannel  string `json:"landscape_server_channel"`
	LandscapeServerRevision int    `json:"landscape_server_revision"`
	UbuntuCoreSeries        string `json:"ubuntu_core_series"`
	UbuntuCoreDeviceName    string `json:"ubuntu_core_device_name"`
	UbuntuCoreCount         int    `json:"ubuntu_core_count"`
	LxdVMCount              int    `json:"lxd_vm_count"`
	LxdSeries               string `json:"lxd_series"`
	LxdVMName               string `json:"lxd_vm_name"`
	PathToGPGPrivateKey     string `json:"path_to_gpg_private_key"`
	GPGPrivateKeyContent    string `json:"gpg_private_key_content"`
	LandscapeServerUnits    int    `json:"landscape_server_units"`
	PostgreSQLUnits         int    `json:"postgresql_units"`
	RabbitMQServerUnits     int    `json:"rabbitmq_server_units"`
	SMTPHost                string `json:"smtp_host"`
	SMTPPort                int    `json:"smtp_port"`
	SMTPUsername            string `json:"smtp_username"`
	SMTPPassword            string `json:"smtp_password"`
	Architecture            string `json:"architecture"`
}

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
	varsPath := filepath.Join(tfDir, TfVarsJsonFileName)

	if _, err := os.Stat(varsPath); err != nil {
		if os.IsNotExist(err) {
			return "", fmt.Errorf("tfvars file not found: %s", varsPath)
		}
		return "", err
	}

	return varsPath, nil
}

func ParseTfJsonVars(filename string) (*Config, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return &Config{}, err
	}

	var config Config
	err = json.Unmarshal(content, &config)
	if err != nil {
		return &Config{}, fmt.Errorf("parse errors: %s", err)
	}

	fmt.Printf("config: %v", config)

	return &config, nil
}
