FROM ntrlmt/rpi-raspbian-jessie-armhf-devel:latest
MAINTAINER ntrlmt

#ROS installation
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116 && \
    apt-get update && \
    apt-get upgrade
RUN apt-get install -y python-rosdep python-rosinstall-generator python-wstool python-rosinstall  && \
    rosdep init && rosdep update
RUN mkdir -p ~/catkin_ws
WORKDIR /root/catkin_ws
RUN rosinstall_generator perception --rosdistro kinetic --deps --wet-only --tar > kinetic-perception-wet.rosinstall && \
    wstool init src kinetic-perception-wet.rosinstall

RUN mkdir -p ~/catkin_ws/external_src && \
    cd ~/catkin_ws/external_src && \
    wget http://sourceforge.net/projects/assimp/files/assimp-3.1/assimp-3.1.1_no_test_models.zip/download -O assimp-3.1.1_no_test_models.zip && \
    unzip assimp-3.1.1_no_test_models.zip && \
    cd assimp-3.1.1 && \
    cmake . && \
    make && \
    sudo make install

WORKDIR /root/catkin_ws/
RUN rosdep install -y --from-paths src --ignore-src --rosdistro kinetic -r --os=debian:jessie
# Fixed eigen3 cmake error  
RUN sed -e "/^find_package(Eigen3 REQUIRED)/s/^/#/" -e "/^#find_package(Eigen3 REQUIRED)/afind_package(PkgConfig)\npkg_search_module(Eigen3 REQUIRED eigen3)" -i.bak ./src/geometry/eigen_conversions/CMakeLists.txt
RUN sed -e "/^find_package(Eigen3 REQUIRED)/s/^/#/" -e "/^#find_package(Eigen3 REQUIRED)/afind_package(PkgConfig)\npkg_search_module(Eigen3 REQUIRED eigen3)" -i.bak ./src/perception_pcl/pcl_ros/CMakeLists.txt

RUN ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/kinetic -j2

WORKDIR /root/catkin_ws/src
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; catkin_init_workspace'
WORKDIR /root/catkin_ws/
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash' && \
    echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc && \
    echo "unset GTK_IM_MODULE" >> ~/.bashrc

CMD ["/bin/bash"]
