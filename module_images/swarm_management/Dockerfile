#Build the base ressources.
FROM python:alpine3.7 

RUN apk update && apk add git
RUN apk add --no-cache bash

#Define arguments
ARG github_repo='swarm_management'
ARG github_branch='release'

ENV github_repo $github_repo
ENV github_branch $github_branch
ENV AM_I_IN_A_DOCKER_CONTAINER=Yes

RUN echo $github_repo
RUN echo $github_branch

EXPOSE 5000

COPY ./* /app/
WORKDIR /app

#Clone the build environment
RUN git clone https://github.com/R2D2-2019/r2d2-python-build
#Set the pythonpath so that modules can be run
WORKDIR /app/r2d2-python-build
RUN git checkout release

ENV PYTHONPATH "${PYTHONPATH}/app/r2d2-python-build/"

WORKDIR /app/r2d2-python-build/modules

#Clone the module that will run in this container
RUN git clone https://github.com/R2D2-2019/$github_repo ./$github_repo
WORKDIR /app

#We can't easily access the file from a different working directory, so we move it now, before moving directories.
COPY ./requirements.txt /app/r2d2-python-build/modules/${github_repo}
COPY ./start_module.sh /app/r2d2-python-build/modules/${github_repo}
COPY ./docker_tests.sh /app/r2d2-python-build/modules/${github_repo}

WORKDIR /app/r2d2-python-build/modules/${github_repo}
#Checkout the selected branch
RUN git checkout $github_branch
#Install the requirements of the module
RUN pip install -r requirements.txt
RUN touch module.log
RUN ["chmod", "+x", "./start_module.sh"]
RUN ["chmod", "+x", "./docker_tests.sh"]
ENTRYPOINT [ "./start_module.sh" ]