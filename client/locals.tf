locals {
  # https://documentation.ubuntu.com/lxd/latest/architectures/
  juju_arch_to_lxd_arch = { "arm64" : "aarch64", "amd64" : "x86_64", "ppc64el" : "ppc64le", "s390x" : "s390x", "riscv64" : "riscv64" }
}
