
# Setting up OAuth Authentication for the client website

The react client website uses OAuth authentication protocol for user authentication. The PKCE authentication flow of OAuth protocol is used for the client website. The authentication has to be setup on a gitlab server. **An oauth application needs to be created on a gitlab instance under admin user**. Then all other users can use the same gitlab instance for oauth authentication. This means commercial gitlab.com can not be used for multi-user authentication system required by DTaaS. The simplest way to make this work is to setup OAuth application as [instance wide authentication type](https://docs.gitlab.com/ee/integration/oauth_provider.html#create-an-instance-wide-application).

Before setting up oauth application on gitlab, you need to first decide on the hostname for your website. We recommend using a self-hosted gitlab instance which will be used in the other parts of the DTaaS application.

Two more URLs are required for the PKCE authentication flow to work properly. They are the **callback URL** and **logout URL**. The callback URL tells the oauth provider the URL of the page that all the signed in users are shown. This URL will be different from the landing homepage of the DTaaS application. The logout URL is the URL that will be shown after a user logs out.

Here is an example for hosting a DTaaS application without any basename.

```txt
DTaaS application URL: https://foo.com
Gitlab instance URL: https://foo.gitlab.com
Callback URL: https://foo.com/Library
Logout URL: https://foo.com
```

If you choose to host your DTaaS application with a basename (say bar), then the URLs change to:

```txt
DTaaS application URL: https://foo.com/bar
Gitlab instance URL: https://foo.gitlab.com
Callback URL: https://foo.com/bar/Library
Logout URL: https://foo.com/bar
```

During the creation of oauth application on gitlab, you need to decide on the scope of this oauth application. Choose `openid profile read_user read_repository api` scopes.

After successful creation of oauth application, gitlab generates an application ID. This application ID is a long string of HEX values. You need to note this down and use in configuration files. An example oauth Client ID is: `934b98f03f1b6f743832b2840bf7cccaed93c3bfe579093dd0942a433691ccc0`.

The mapping between the oauth URLs and the environment variables in `env.js` is shown below.

| URL | Variable name in env.js |
|:---|:---|
| DTaaS application URL | REACT_APP_URL |
| Gitlab instance URL | REACT_APP_AUTH_AUTHORITY |
| Callback URL | REACT_APP_REDIRECT_URI |
| Logout URL | REACT_APP_LOGOUT_REDIRECT_URI |
||

The same **URLs** and **Client ID** are useful for both the regular hosting of DTaaS application and also as the CI/CD server to be used for the development work.

## Development Environment

There needs to be a valid callback and logout URLs for development and testing purposes. You can use the same oauth application id for both development, testing and deployment scenarios. Only the callback and logout URLs change. It is possible to register multiple callback URLs in one oauth application. In order to use oauth for development and testing on developer computer (localhost), you need to add the following to oauth callback URL.

```txt
DTaaS application URL: http://localhost:4000
Callback URL: http://localhost:4000/Library
Logout URL: http://localhost:4000
```

The port 4000 is the default port for running the client website.

## Multiple DTaaS applications

The DTaaS is a regular web application. It is possible to host multiple DTaaS applications on the same server. The only requirement is to have a distinct URLs. You can have three DTaaS applications running at the following URLs.

```txt
https://foo.com/au
https://foo.com/acme
https://foo.com/bar
```

All of these instances can use the same gitlab instance for authentication.

| DTaaS application URL | Gitlab Instance URL | Callback URL | Logout URL | Application ID |
|:----|:----|:----|:----|:----|
| https://foo.com/au | https://foo.gitlab.com | https://foo.com/au/Library | https://foo.com/au | autogenerated by gitlab |
| https://foo.com/acme | https://foo.gitlab.com | https://foo.com/au/Library | https://foo.com/au | autogenerated by gitlab |
| https://foo.com/bar | https://foo.gitlab.com | https://foo.com/au/Library | https://foo.com/au | autogenerated by gitlab |
||

If you are hosting multiple DTaaS instances on the same server, do not a DTaaS with a null basename on the same server. Even though it works well, the setup is confusing to setup and may lead to maintenance issues.