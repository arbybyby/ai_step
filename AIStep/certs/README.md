# ASP.NET Core HTTPS Development Certificate

This docker-compose configuration mounts your local ASP.NET development certificate from `~/.aspnet/https`.

## Setup

1. Generate the ASP.NET Core development certificate (if not already done):

   ```bash
   dotnet dev-certs https -ep ~/.aspnet/https/aspnetapp.pfx -p <password>
   dotnet dev-certs https --trust
   ```

2. Set the certificate password in `.env` file (create it next to `docker-compose.yml`):

   ```
   ASPNETCORE_Kestrel__Certificates__Default__Password=<password>
   ```

3. Run docker-compose:

   ```bash
   docker compose up
   ```

The application will be available at:
- HTTP: http://localhost:5050
- HTTPS: https://localhost:5051

## Windows Users

On Windows, the certificate path is typically `%USERPROFILE%\.aspnet\https`. Update the volume path in `docker-compose.yml` to:

```yaml
volumes:
  - ${USERPROFILE}\.aspnet\https:/https:ro
```

Or use Windows path directly:

```yaml
volumes:
  - C:\Users\YourUsername\.aspnet\https:/https:ro
