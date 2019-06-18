#Build the base ressources.
FROM python:alpine3.7 
COPY ./* /app/
WORKDIR /app

RUN apk update && apk add git

#Define arguments
ARG github_branch='release'

ENV github_branch $github_branch
ENV AM_I_IN_A_DOCKER_CONTAINER=Yes

RUN echo $github_repo
RUN echo $github_branch

EXPOSE 5000

#Clone the build environment
RUN git clone https://github.com/R2D2-2019/r2d2-python-build
#Set the pythonpath so that modules can be run
WORKDIR /app/r2d2-python-build
RUN git checkout ${github_branch}

ENV PYTHONPATH "${PYTHONPATH}/app/r2d2-python-build/"

WORKDIR /app
COPY ./requirements.txt /app/r2d2-python-build/
COPY ./start_module.sh /app/r2d2-python-build/
WORKDIR /app/r2d2-python-build/
#Install the requirements of the module
RUN pip install -r requirements.txt
RUN ["chmod", "+x", "./start_module.sh"]
ENTRYPOINT [ "./start_module.sh" ]