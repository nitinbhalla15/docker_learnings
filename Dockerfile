#PHASE 1 OF BUILD

# Layer 1 (Defining Base image for first phase of image build)
FROM maven AS mvn_builder
# Layer 2 (Creating a working directory for all the application build to happen inside this dir)
WORKDIR /app
# Layer 3 (Copying pom.xml to the working directory to download all the dependency required to run the application image)
COPY pom.xml .
# Layer 4 (Downloading all the dependencies from the central maven repository in offline mode which means post downloading the dependencies
# maven command can be used to build the project in offline mode when there are some network issues
RUN mvn dependency:go-offline
# Layer 5 (Copying src dir to the working directory which will be using the depencies downloaded in prev step and will be used
# for build
# Why src was copyed later after pom.xml ?
# -> As Docker images use layerd architecture under the hood so every command or actions will be a separate layer
# Layers only reconciliate when that particular layer changes so copying and downloading dependencies first will isolate the
# main logic layer as if code changes then that layer will be build again but dependencies harldy change in project which
# will result in not  building that layer again which will result in efficient image creation
# We try to create thin layers
COPY src src
# Layer 6 (Actually building the application and creating jar)
RUN mvn package
# Layer 7 (Running the jar build from prev step)
# Creating jar in a layer mode which will create a jar and split the jar into layers to be used by docker to create efficient image in build
# process -> jar will split up into : dependencies , snapshot-dependencies , application and spring-boot-loader componets
RUN java -Djarmode=layertools -jar target/docker-0.0.1-SNAPSHOT.jar extract


#PHASE 2 OF BUILD
FROM openjdk
#RUN addgroup -S demo && adduser -S demo -G demo
#USER demo
WORKDIR /app
#Now we will copy different layer extracted from the jar in the directories and then run the spring boot loader layer
# Copying each layer differently will increase the layers which can increase efficiency of image build
COPY --from=mvn_builder app/dependencies/ ./
COPY --from=mvn_builder app/spring-boot-loader/ ./
COPY --from=mvn_builder app/snapshot-dependencies/ ./
COPY --from=mvn_builder app/application/ ./
ENTRYPOINT ["java","org.springframework.boot.loader.launch.JarLauncher"]