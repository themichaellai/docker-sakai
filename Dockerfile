FROM library/ubuntu:15.04

#adds the add-apt-repo tool
RUN apt-get install -y software-properties-common

#install oracle java 8
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer

#install tomcat
WORKDIR /opt
RUN wget http://apache.go-parts.com/tomcat/tomcat-8/v8.0.26/bin/apache-tomcat-8.0.26.tar.gz
RUN tar -zxvf apache-tomcat-8.0.26.tar.gz
RUN mv apache-tomcat-8.0.26 tomcat

# install mysql
RUN echo "mysql-server mysql-server/root_password password lol" | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password lol' | debconf-set-selections
RUN apt-get -yq install mysql-server

#install maven 3.3.3 & git
RUN wget http://mirrors.sonic.net/apache/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
RUN tar -zxvf apache-maven-3.3.3-bin.tar.gz
RUN mv apache-maven-3.3.3 /usr/local/maven
RUN ln -s /usr/local/maven/bin/mvn /usr/bin/mvn
RUN apt-get install -y git

#install ruby 2.2.3
RUN apt-get -y install git-core curl zlib1g-dev build-essential libssl-dev  \
                       libreadline-dev libyaml-dev libsqlite3-dev sqlite3   \
                       libxml2-dev libxslt1-dev libcurl4-openssl-dev        \
                       python-software-properties libffi-dev
RUN git clone git://github.com/sstephenson/rbenv.git /.rbenv
ENV PATH "/.rbenv/bin:$PATH"
RUN eval "$(rbenv init -)"
RUN git clone git://github.com/sstephenson/ruby-build.git /.rbenv/plugins/ruby-build
ENV PATH "/.rbenv/plugins/ruby-build/bin:$PATH"
RUN git clone https://github.com/sstephenson/rbenv-gem-rehash.git /.rbenv/plugins/rbenv-gem-rehash
RUN rbenv install 2.2.3
RUN rbenv global 2.2.3

#install sakai
RUN git clone https://github.com/sakaiproject/sakai.git /sakai
WORKDIR /sakai
RUN mvn clean install sakai:deploy -Dmaven.tomcat.home=/tomcat

#configure mysql
ADD ./mysql/my.conf /etc/mysql/my.conf
RUN mysql -uroot "create database sakai default character set utf8;"
RUN mysql -uroot "grant all privileges on sakai.* to 'sakai'@'localhost' identified by 'ironchef';"
RUN mysql -uroot "grant all privileges on sakai.* to 'sakai'@'127.0.0.1' identified by 'ironchef';"

#configure tomcat
ADD ./tomcat/context.xml /tomcat/conf/context.xml
ADD ./tomcat/server.xml /tomcat/conf/server.xml
RUN rm -rf /tomcat/webapps/*
RUN wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.36.tar.gz
RUN tar -zxvf mysql-connector-java-5.1.36/mysql-connector-java-5.1.36.tar.gz
RUN mv mysql-connector-java-5.1.36-bin.jar /tomcat/comm

#configure sakai
ADD ./tomcat/sakai.properties /tomcat/sakai/sakai.properties

EXPOSE 8080

CMD ["/bin/bash", "./tomcat/start-sakai.sh"]
