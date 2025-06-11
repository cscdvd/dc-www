#!/bin/bash

NAME="source"                                  
DJANGODIR=/home/example/www/source                
SOCKFILE=/home/example/www/tmp/gunicorn.sock  
USER=example                                      
GROUP=example                                      
NUM_WORKERS=3                                      
DJANGO_SETTINGS_MODULE=source.settings          
DJANGO_WSGI_MODULE=source.wsgi                  
echo "Starting $NAME as `whoami`"


cd $DJANGODIR
source /home/example/www/.venv/bin/activate
export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
export PYTHONPATH=$DJANGODIR:$PYTHONPATH

# Create the run directory if it doesn't exist

RUNDIR=$(dirname $SOCKFILE)
test -d $RUNDIR || mkdir -p $RUNDIR

exec gunicorn ${DJANGO_WSGI_MODULE}:application \
  --name $NAME \
  --workers $NUM_WORKERS \
  --user=$USER --group=$GROUP \
  --bind=unix:$SOCKFILE \
  --log-level=info \
  --log-file=/home/example/www/log/gunincorn.log