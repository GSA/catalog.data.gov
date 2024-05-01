This folder is used to install local extensions for development.
Clone here any extension that you want to work on. This folder in mounted on
the `ckan-dev` service, so any extension located here will be installed when
booting up Docker Compose in development mode 
(`docker compose -f docker-compose.dev.yml up`).
If running the CKAN container standalone you will need to mount the folder
yourself.
