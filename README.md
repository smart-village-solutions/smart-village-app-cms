# Smart Village App - CMS

![Smart Village App Logo](https://github.com/smart-village-solutions/smart-village-app-app/raw/master/smart-village-app-logo.png)

Welcome to the CMS of the Smart Village App, an integral part of the innovative Smart Village App project. We invite you to visit our [German website](https://smart-village.app) to present your ideas and visions and contribute to our community-driven initiative. 🌟

[![Maintainability](https://api.codeclimate.com/v1/badges/9290fe5d4ddb83fff2bd/maintainability)](https://codeclimate.com/github/ikuseiGmbH/smart-village-app-cms/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/9290fe5d4ddb83fff2bd/test_coverage)](https://codeclimate.com/github/ikuseiGmbH/smart-village-app-cms/test_coverage)

## Setup Process

### Master Key Configuration

Ensure the creation of `config/master.key` with the appropriate key.

### Node Version Setup

This CMS requires Node.js version 14. To set up:

#### Using NVM (Node Version Manager):

- If NVM is not installed, find installation instructions on the [NVM GitHub page](https://github.com/nvm-sh/nvm).
- Switch to Node.js v14 with:
```bash
nvm use 14
```
- Install Node.js v14 through NVM if not previously installed.

### Asset Precompilation

Within your CMS project directory, execute:
```bash
rails assets:precompile
```

### Logging In

- Access the CMS at `http://localhost:3000`.
- Log in using credentials created in the Smart Village App Mainserver on the [master branch](https://github.com/smart-village-solutions/smart-village-app-mainserver/tree/master):
 - **Example credentials from the User** :
    - Username: `admin@smart-village.app`
    - Password: `my_new_password`
 - Ensure the user has the necessary rights to log in to the CMS server. If you encounter an error stating "E-Mail oder Passwort ist falsch," it indicates a problem with either the email, password, or user permissions.
- Please note: The CMS requires the Main-Server to be operational for full functionality with the **Master-Branch**. Make sure the Main-Server is running at `http://localhost:4000`.
- **Important**: Ensure that the branches of the CMS and the Main-Server are compatible. Mismatched branches may lead to compatibility issues or incomplete functionality.

## Technical Stack

- Ruby version: 2.7.5
- Rails version: 6.1.4
