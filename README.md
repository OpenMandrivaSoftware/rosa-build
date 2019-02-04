RosaLab ABF
===========

A distributed environment to build distributions, supporting all steps from managing source code to creating ISO images. If you have any problems or requests please contact
[support](https://abf.rosalinux.ru/contact).

**Note: This Documentation is in a beta state. Breaking changes may occur.**

[![Join the chat at https://gitter.im/rosa-abf/rosa-build](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/rosa-abf/rosa-build?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
 [![Build Status](https://travis-ci.org/rosa-abf/rosa-build.png?branch=master)](https://travis-ci.org/rosa-abf/rosa-build) [![Dependency Status](https://gemnasium.com/rosa-abf/rosa-build.png)](https://gemnasium.com/rosa-abf/rosa-build) <a href="https://codeclimate.com/github/rosa-abf/rosa-build"><img src="https://codeclimate.com/github/rosa-abf/rosa-build.png" /></a>

* [API](http://abf-doc.rosalinux.ru/abf/api/)
* [Integration with FileStore (.abf.yml)](http://abf-doc.rosalinux.ru/abf/file_store_integration/)
* [ISO build environment](http://abf-doc.rosalinux.ru/abf/iso_build/)
* [Package build environment](http://abf-doc.rosalinux.ru/abf/scripts/)
* [Deployment](http://abf-doc.rosalinux.ru/abf/deployment/)

## Contributing to rosa-build

A ruby translation project managed on [Locale](http://www.localeapp.com/) that's open to all!

- Edit the translations directly on the [rosa-build](http://www.localeapp.com/projects/public?search=rosa-build) project on Locale.
- **That's it!**
- The maintainer will then pull translations from the Locale project and push to Github.

Happy translating!
test 1

[20:07] <HisShadow> bero: there's 
ABFUI container that's responsible for the web interface and API that workers use to interact with abf. 
Sidekiq is a ruby library that is a background job executor. It uses redis to store job information. 
Some stuff can't just run in the web interface code, stuff like mass build creation for example. You need to create a lot of build lists which takes time, so it's not practical to put it into the web interface itself. 
Our sidekiq executes jobs like creating mass builds, or changing build list statuses. When a builder sends feedback a job gets scheduled and processed by our main sidekiq container changing status of a build list and updating files if there are any. Publisher and ISO builder are both sidekiq workers too that run 1 job: publishing and product building respectivly. Postgresql container is our main database(well that should be obvious :))


How to kill stucked builds

```BuildList.where(id: [362471, 362473]).destroy_all```
