FROM openknowledge/ckan-dev:2.8

MAINTAINER Your Name Here <you@example.com>

# Set timezone
ARG TZ
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime
RUN echo $TZ > /etc/timezone

COPY requirements.txt ${APP_DIR}

RUN pip install -r requirements.txt
