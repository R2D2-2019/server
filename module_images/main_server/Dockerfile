#Build the base ressources.
FROM python:alpine3.7 
COPY ./* /app/
WORKDIR /app

RUN apk update && apk add git

#Define arguments
ARG github_repo='r2d2-python-build'
ARG github_branch='florianhumblot-patch-1'

ENV github_repo $github_repo
ENV github_branch $github_branch
ENV AM_I_IN_A_DOCKER_CONTAINER=Yes

RUN echo $github_repo
RUN echo $github_branch

EXPOSE 5000


#Clone the module that will run in this container
RUN git clone https://github.com/R2D2-2019/$github_repo ./$github_repo
COPY ./requirements.txt /app/r2d2-python-build/
ENV PYTHONPATH "${PYTHONPATH}/app/r2d2-python-build/"
WORKDIR /app/r2d2-python-build
#Checkout the selected branch
RUN git checkout $github_branch
#Install the requirements of the module
RUN pip install -r requirements.txt
RUN touch module.log

ENTRYPOINT [ "python3", "manager/manager.py" ]
