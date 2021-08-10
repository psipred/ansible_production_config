Production version of our ansible config

Ask admin for secrets contents to use.

Now update the secrets/production_secrets.yaml file as follows:

1) Create a personal access token for github, following the instructions [here.](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-token)
Your github token must have full scope for private repos, so that
you can download blast_cache.

2) Now add two lines to the bottom of secrets/production_secrets.yaml
```
username_password: <this is your github login name>:<this is a github token >
user: <your user name on the staging machines>
```
replacing the details with your personal information. This will enable you to download blast_cache.git via ansible, ensuring that your information is only ever on your own machine.
