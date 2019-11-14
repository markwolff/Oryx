# Oryx Build - GitHub Action

## About

This GitHub Action will use the `oryx build` command to generate a build script for the given repository, and then run that script in order to build the web app. Once built, the contents of the repository can be tested and/or deployed to Azure App Service.

## Usage

The Oryx Build GitHub Action can be included in a repository's workflow by using `microsoft/oryx/actions/oryx-build@master`.

The following parameters can be set as a part of the action:

- `source-directory`
    - Relative path (within the repository) to the source directory of the project you want to build; if no value is provided for this, the root of the repository ('GITHUB_WORKSPACE' environment variable) will be built.
- `output-directory`
    - Path to the directory on the container that the build artifacts will be placed; if no value is provided, the given platform will determine where the build artifacts are placed within the repository.
- `platform`
    - Programming platform used to build the web app; if no value is provided, Oryx will determine the platform to build with. The supported values are "dotnet", "nodejs", "php" and "python".
- `platform-version`
    - Version of the programming platform used to build the web app; if no value is provided, Oryx will determine the version needed to build the repository.

## Examples

### Building a web app

The following is a sample of building a web app in a repository whenever a commit is pushed:

```
on: push

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Cloning repository
        uses: actions/checkout@v1

      - name: Running Oryx to build web app
        uses: microsoft/oryx/actions/oryx-build@master
```

### Deploying an Azure Web App

The following is an end-to-end sample of building a web app in a repository and then deploying it to Azure whenever a commit is pushed:

```
on: push

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Cloning repository
        uses: actions/checkout@v1

      - name: Running Oryx to build web app
        uses: microsoft/oryx/actions/oryx-build@master

      - name: Deploying web app to Azure
        uses: azure/appservice-actions/webapp@master
        with:
          app-name: <WEB_APP_NAME>
          publish-profile: ${{ secrets.AZURE_WEB_APP_PUBLISH_PROFILE }}
```

The following variable should be replaced in your workflow:

- `<WEB_APP_NAME>`
    - Name of the web app that's being deployed

The following variable should be set in the GitHub repository's secrets store:

- `AZURE_WEB_APP_PUBLISH_PROFILE`
    - The contents of the publish profile file (`.publishsettings`) used to deploy the web app; for more information on setting this secret, please see the [`azure/appservice-actions/webapp`](https://github.com/Azure/appservice-actions) action