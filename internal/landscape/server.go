package landscape

import (
	"context"
	"encoding/base64"
	"fmt"
	"log"
	"os/exec"

	"github.com/hashicorp/terraform-exec/tfexec"
)

type LandscapeServer struct {
	ctx        context.Context
	modulePath string
	// TODO: #7 Don't pass in entire TFVars file (just use unmarshalled vars)
	tfVarsFilePath    string
	b64SSLCert        string
	b64SSLKey         string
	terraformExecPath string
	logger            *log.Logger
	tf                *tfexec.Terraform
}

func (ls *LandscapeServer) New(ctx context.Context, modulePath string, tfVarsFilePath string, sslCertPath string, sslKeyPath string, terraformExecPath string, logger *log.Logger) (*LandscapeServer, error) {
	var sslCert string
	var sslKey string

	if sslCertPath != "" {
		logger.Println("Reading SSL cert with 'sudo'...")
		data, err := exec.Command("sudo", "cat", sslCertPath).Output()
		if err != nil {
			return nil, fmt.Errorf("failed to read SSL cert: %w", err)
		}
		sslCert = string(data)
	}

	if sslKeyPath != "" {
		logger.Println("Reading SSL key with 'sudo'...")
		data, err := exec.Command("sudo", "cat", sslKeyPath).Output()
		if err != nil {
			return nil, fmt.Errorf("failed to read SSL key: %w", err)
		}
		sslKey = string(data)
	}

	tf, err := tfexec.NewTerraform(modulePath, terraformExecPath)
	if err != nil {
		return nil, fmt.Errorf("failed to create terraform client for module at %s: %w", modulePath, err)
	}

	base64EncodedSSLCert := base64.StdEncoding.EncodeToString([]byte(sslCert))
	base64EncodedSSLKey := base64.StdEncoding.EncodeToString([]byte(sslKey))

	return &LandscapeServer{
		ctx:               ctx,
		modulePath:        modulePath,
		tfVarsFilePath:    tfVarsFilePath,
		b64SSLCert:        base64EncodedSSLCert,
		b64SSLKey:         base64EncodedSSLKey,
		terraformExecPath: terraformExecPath,
		logger:            logger,
		tf:                tf,
	}, nil
}

func (ls *LandscapeServer) Init() error {
	ls.logger.Printf("Attempting to initialize Terraform module at: %s", ls.modulePath)
	err := ls.tf.Init(ls.ctx, tfexec.Upgrade(true))
	if err != nil {
		return fmt.Errorf("failed to run 'terraform init' for module at %s: %w", ls.modulePath, err)
	}
	ls.logger.Printf("Terraform module at %s initialized successfully.", ls.modulePath)
	return nil
}

func (ls *LandscapeServer) Plan() error {
	ls.logger.Printf("Running terraform plan...")
	_, err := ls.tf.Plan(ls.ctx, tfexec.VarFile(ls.tfVarsFilePath))
	if err != nil {
		return fmt.Errorf("failed to run 'terraform plan': %w", err)
	}
	ls.logger.Printf("Terraform plan completed successfully.")
	return nil
}

func (ls *LandscapeServer) Apply() error {
	ls.logger.Printf("Running terraform apply...")
	err := ls.tf.Apply(ls.ctx, tfexec.VarFile(ls.tfVarsFilePath))
	if err != nil {
		return fmt.Errorf("failed to run 'terraform apply': %w", err)
	}
	ls.logger.Printf("Terraform apply completed successfully.")
	return nil
}

func (ls *LandscapeServer) Destroy() error {
	ls.logger.Printf("Running terraform destroy...")
	err := ls.tf.Destroy(ls.ctx, tfexec.VarFile(ls.tfVarsFilePath))
	if err != nil {
		return fmt.Errorf("failed to run 'terraform destroy': %w", err)
	}
	ls.logger.Printf("Terraform destroy completed successfully.")
	return nil
}
