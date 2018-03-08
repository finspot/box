#===========
#Build Stage
#===========
FROM elixir:1.6 as build

#Copy the source folder into the Docker image
COPY . .

#Install dependencies and build Release
RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix release

#Extract Release archive to /rel for copying in next stage
RUN APP_NAME="box" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    tar -xzf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

#================
#Deployment Stage
#================
FROM elixir:1.6

#Set environment variables and expose port
EXPOSE 4000
ENV REPLACE_OS_VARS=true \
    PORT=4000

#Copy and extract .tar.gz Release file from the previous stage
COPY --from=build /export/ /opt

#Set default entrypoint and command
ENTRYPOINT ["/opt/bin/box"]
CMD ["foreground"]
