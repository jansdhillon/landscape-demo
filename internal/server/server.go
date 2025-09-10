package server

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-exec/tfexec"
)

type DeployServerOption struct {
	B64SSLCert           *string
	B64SSLKey            *string
	GPGPrivateKeyContent *string
}

func NewDeployServerOpt(sslCert, sslKey, gpgPrivateKey *string) DeployServerOption {
	return DeployServerOption{
		B64SSLCert:           sslCert,
		B64SSLKey:            sslKey,
		GPGPrivateKeyContent: gpgPrivateKey,
	}
}

func DeployLandscapeServer(ctx context.Context, tf *tfexec.Terraform, workspaceName string, opts ...DeployServerOption) error {
	if workspaceName == "" {
		return fmt.Errorf("workspace_name required for deploy_landscape_server")
	}

	var opt DeployServerOption
	if len(opts) > 0 {
		opt = opts[0]
	}

	if opt.GPGPrivateKeyContent == nil || *opt.GPGPrivateKeyContent == "" {
		return fmt.Errorf("gpg_private_key_content required for deploy_landscape_server")
	}

	var applyVars []tfexec.ApplyOption
	applyVars = append(applyVars,
		tfexec.Var(fmt.Sprintf("workspace_name=%s", workspaceName)),
		tfexec.Var(fmt.Sprintf("gpg_private_key_content=%s", *opt.GPGPrivateKeyContent)),
	)

	if opt.B64SSLCert != nil && opt.B64SSLKey != nil &&
		*opt.B64SSLCert != "" && *opt.B64SSLKey != "" {
		applyVars = append(applyVars,
			tfexec.Var(fmt.Sprintf("b64_ssl_cert=%s", *opt.B64SSLCert)),
			tfexec.Var(fmt.Sprintf("b64_ssl_key=%s", *opt.B64SSLKey)),
		)
	}

	err := tf.Apply(ctx, applyVars...)
	if err != nil {
		return fmt.Errorf("error running apply: %w", err)
	}

	return nil
}
