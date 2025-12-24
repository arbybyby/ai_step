Place your certificate file at `aspnetapp.pfx` in this directory.

Create a PFX file and ensure it is readable by Docker. This directory is mounted into the container at `/https` by docker-compose.yml.

Example (PowerShell) to create a self-signed certificate and export to PFX:

$cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My"
$password = ConvertTo-SecureString -String "yourpassword" -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\LocalMachine\My\$($cert.Thumbprint)" -FilePath .\aspnetapp.pfx -Password $password
