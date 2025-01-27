<img src="https://github.com/smart-village-solutions/smart-village-app-app/raw/master/smart-village-app-logo.png" width="150">

# Smart Village App - CMS

[![Maintainability](https://api.codeclimate.com/v1/badges/9290fe5d4ddb83fff2bd/maintainability)](https://codeclimate.com/github/ikuseiGmbH/smart-village-app-cms/maintainability)

Please visit the german website to get in touch with us and present your ideas and visions: https://smart-village.app.

&nbsp;

This cms is one main part of the whole Smart Village App project. For more information visit https://github.com/ikuseiGmbH/smart-village-app.

## Setup process

### Master key configuration

Create `config/master.key` if needed with the correct key.

### Node version setup

The CMS requires Node.js version 14. Follow these steps to set up the correct Node.js version:

#### Using NVM (Node Version Manager):

- If you haven't installed NVM, follow the installation instructions for your operating system.
- Once NVM is installed, use the following command to switch to Node.js v14:

  ```bash
  nvm use 14
  ```
- If Node.js v14 is not installed, NVM will prompt you to install it. Follow the instructions provided by NVM.

### Asset precompilation

#### Precompile Assets with Rails:

- Run the following command in the terminal within your CMS project directory:

    ```bash
    rails assets:precompile
    ```

### Login

- login into CMS at http://localhost:3000 with user name "admin@smart-village.app" and password “my_new_password”
- you need to have the Main-Server running  to connect with at http://localhost:4000

## Tech Stack

- Ruby version: 2.7.5
- Rails version: 6.1.4
