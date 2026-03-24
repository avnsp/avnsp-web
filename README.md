AVNSP
=========
This is a distributed web application. Where the different parts are connected via AMQP (RabbitMQ).

For example the image upload works like this:
The web app has a page where users can select which files to upload.
When the server has received the images the web apps responsibilites stops. It send the files on to a queue.
On the other end a photo processing app handles compression, scaling and uploading the images to a persistent storage.

Requirements
------------
* Ruby-2.4
* RabbitMQ 3.6
* Postgresql 9.2 +

### Setup env
```
createdb avnsp
rabbitmqctl add_vhost avnsp
rabbitmqctl set_permission -p avnsp .* .* .*
```
### Migrate db locally
```
sequel -m migrations/ postgres://localhost/avnsp
```
### Start
```
bundle install
foreman start
```

### Local development with Docker Compose

The easiest way to get a local environment running is with Docker Compose, which starts the app together with PostgreSQL and LavinMQ:

```
docker compose up --build
```

On first start, a default admin user is created and its credentials are printed to the console. The default password can be overridden with the `ADMIN_PASSWORD` environment variable.

### Docker

Build the image:
```
docker build -t avnsp-web .
```

Run the container:
```
docker run -p 9393:9393 \
  -e ELEPHANTSQL_URL=postgres://user:pass@host/avnsp \
  -e CLOUDAMQP_URL=amqp://user:pass@host/avnsp \
  -e SESSION_SECRET=<at_least_64_byte_secret> \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  avnsp-web
```

### deploy

Deployment is handled automatically via the GitHub → Heroku integration. Merging to `main` triggers a deploy.
