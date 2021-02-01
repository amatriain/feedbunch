# Installation

Currently the only supported method to install FeedBunch is using [docker-compose](https://docs.docker.com/compose/). 
You will need a computer with [Docker](https://www.docker.com/) up and running and docker-compose installed. You can 
also run it in a [docker-swarm](https://docs.docker.com/engine/swarm/) cluster.

## The docker-compose.yml file

You can find a [sample docker-compose.yml file here](FeedBunch-docker/docker-compose.yml). You should customize some
values in the file before using it to deploy the stack.

Some environment variables are present multiple times in the docker-compose.yml file, because they are passed to 
multiple services. The tables below indicate which services are passed each environment variable. **You must write
the same value every time an environment variable appears in the file; this is, each environment variable must
have just one value, no matter how many time it appears in the file**.

### Port

The whole stack only exports one HTTP port, used to access the web GUI. It's exported by the ```webapp``` service
and it takes the value 9292 by default. You can customize the port mapping but take care not to change the internal
9292 port; i.e. if you want the app to be accessible at port 8000 you can replace the port mapping in the file 
with:

```
ports:
    - '8000:9292'
```

TLS is not supported natively. If you want your FeedBunch installation to be accessible via HTTPS, you will have
to configure a reverse proxy that handles TLS.

### Default administrator account

When the stack is deployed for the first time, an administrator account will be created. You can customize this
account setting environment variables in the docker-compose.yml file when deploying for the first time:

| Environment variable  | Services              | Default value     |
|-----------------------|-----------------------|-------------------|
| ADMIN_EMAIL           | webapp, background    |   some@email.com  |
| ADMIN_USERNAME        | webapp                |   admin           |
| ADMIN_PASSWORD        | webapp                |   feedbunch_admin |

The email of this administrator account will also be used as the sender for emails sent by FeedBunch (e.g. to 
notify of the result of an OMPL export).

### Demo user

You can choose if a demo user is enabled for your FeedBunch installation. This is a user with publicly available
credentials (i.e. anyone can log in as the demo user). This user is different from regular users: it cannot be
deleted and any changes in its subscriptions (e.g. added or removed feeds) are reverted every hour.

| Environment variable  | Services              | Default value     |
|-----------------------|-----------------------|-------------------|
| DEMO_USER_ENABLED     | webapp, background    |   false           |

### Enable or disable self-signups

You can choose whether your FeedBunch installation will allow self-signups; i.e. if anyone with a valid email 
address can register a user account. If you want control over who can login in your FeedBunch installation, 
disable self-signups. If self-signups are disabled only an administrator can create new user accounts.
 
| Environment variable  | Services              | Default value     |
|-----------------------|-----------------------|-------------------|
| SIGNUPS_ENABLED       | webapp, background    |   false           |

Self-signups are disabled by default.

### Sending emails

FeedBunch must connect to an SMTP server to send emails. By default it attempts to send emails through gmail, but
you can tell it to use another SMTP server if you want.

| Environment variable  | Services              | Default value     |
|-----------------------|-----------------------|-------------------|
| SMTP_ADDRESS          | webapp, background    |   smtp.gmail.com  |
| SMTP_PORT             | webapp, background    |   587             |
| SMTP_USER_NAME        | webapp, background    |   gmail_user      |
| SMTP_PASSWORD         | webapp, background    |   gmail_password  |
| SMTP_AUTHENTICATION   | webapp, background    |   plain           |

### Links in emails

Some emails sent by FeedBunch will contain links to your installation. For these links to be correct, you'll have
to configure the URL in which your FeedBunch installation can be accessed in an environment variable:

| Environment variable  | Services              | Default value                 |
|-----------------------|-----------------------|-------------------------------|
| EMAIL_LINKS_URL       | webapp, background    |   https://www.feedbunch.com   |

## Volumes

Some docker volumes must be shared between services in the docker stack for FeedBunch to work correctly. It is 
suggested you don't change the volumes configuration in the sample docker-compose.yml file.

There's usually no need to access these volumes from outside FeedBunch, so it is suggested you allow Docker to manage
them instead of bind-mounting them to directories in your host.