package landscape

import (
	"context"
	"fmt"
	"log"

	"github.com/hashicorp/terraform-exec/tfexec"
)

type LandscapeClient struct {
	ctx               context.Context
	modulePath        string
	tfVarsFilePath    string
	terraformExecPath string
	logger            *log.Logger
	tf                *tfexec.Terraform
	selfSignedServer  bool
}

func (ls *LandscapeClient) New(ctx context.Context, modulePath string, tfVarsFilePath string, terraformExecPath string, logger *log.Logger, selfSignedServer bool) (*LandscapeClient, error) {

	tf, err := tfexec.NewTerraform(modulePath, terraformExecPath)
	if err != nil {
		return nil, fmt.Errorf("failed to create terraform client for module at %s: %w", modulePath, err)
	}

	return &LandscapeClient{
		ctx:               ctx,
		modulePath:        modulePath,
		tfVarsFilePath:    tfVarsFilePath,
		terraformExecPath: terraformExecPath,
		logger:            logger,
		tf:                tf,
		selfSignedServer:  selfSignedServer,
	}, nil
}

func (ls *LandscapeClient) Init() error {
	ls.logger.Printf("Attempting to initialize Landscape Client module at: %s", ls.modulePath)
	err := ls.tf.Init(ls.ctx, tfexec.Upgrade(true))
	if err != nil {
		return fmt.Errorf("failed to run 'terraform init' for Landscape Client %s: %w", ls.modulePath, err)
	}
	ls.logger.Printf("Landscape Client module at %s initialized successfully.", ls.modulePath)
	return nil
}

func (ls *LandscapeClient) Plan() error {
	ls.logger.Printf("Running terraform plan for Landscape Client...")
	_, err := ls.tf.Plan(ls.ctx, tfexec.VarFile(ls.tfVarsFilePath))
	if err != nil {
		return fmt.Errorf("failed to run 'terraform plan': %w", err)
	}
	ls.logger.Printf("Plan for Landscape Client completed successfully.")
	return nil
}

func (ls *LandscapeClient) Apply() error {
	ls.logger.Printf("Running terraform apply for Landscape Client...")
	err := ls.tf.Apply(ls.ctx, tfexec.VarFile(ls.tfVarsFilePath))
	if err != nil {
		return fmt.Errorf("failed to run 'terraform apply': %w", err)
	}
	ls.logger.Printf("Terraform apply completed successfully.")
	return nil
}

func (ls *LandscapeClient) Destroy() error {
	ls.logger.Printf("Running terraform destroy for Landscape Client...")
	err := ls.tf.Destroy(ls.ctx, tfexec.VarFile(ls.tfVarsFilePath))
	if err != nil {
		return fmt.Errorf("failed to run 'terraform destroy': %w", err)
	}
	ls.logger.Printf("Terraform destroy completed successfully.")
	return nil
}
