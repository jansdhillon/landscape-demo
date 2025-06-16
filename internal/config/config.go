package config

type TfVarsFile struct {
	ProToken            string `json:"pro_token"`
	ModelName           string `json:"model_name"`
	PathToSSHKey        string `json:"path_to_ssh_key"`
	Hostname            string `json:"hostname"`
	Domain              string `json:"domain"`
	AdminEmail          string `json:"admin_email"`
	AdminPassword       string `json:"admin_password"`
	PathToSSLCert       string `json:"path_to_ssl_cert"`
	PathToSSLKey        string `json:"path_to_ssl_key"`
	MinInstall          bool   `json:"min_install"`
	LandscapePPA        string `json:"landscape_ppa"`
	RegistrationKey     string `json:"registration_key"`
	LandscapeServerBase string `json:"landscape_server_base"`
	GPGPrivateKeyPath   string `json:"gpg_private_key_path"`
	UbuntuCoreSeries    string `json:"ubuntu_core_series"`
	IncludeUbuntuCore   bool   `json:"include_ubuntu_core"`
	DeviceName          string `json:"device_name"`
	LXDVMCount          int    `json:"lxd_vm_count"`
	LXDSeries           string `json:"lxd_series"`
	LXDVMName           string `json:"lxd_vm_name"`
}
