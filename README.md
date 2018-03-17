[![GPLv2 Licence](https://badges.frapsoft.com/os/gpl/gpl.png?v=103)](https://opensource.org/licenses/GPL-2.0/)
[![Build Status](https://api.travis-ci.org/ledgersmb/LedgerSMB.svg?branch=master)](https://travis-ci.org/ledgersmb/LedgerSMB)
[![Coverage Status](https://coveralls.io/repos/github/ledgersmb/LedgerSMB/badge.svg?branch=master)](https://coveralls.io/github/ledgersmb/LedgerSMB?branch=master)
[![Docker](https://img.shields.io/docker/pulls/ledgersmb/ledgersmb.svg)](https://hub.docker.com/r/ledgersmb/ledgersmb/)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/795/badge)](https://bestpractices.coreinfrastructure.org/projects/795)

Como coveralls actualmente tiene un error con sus credenciales para el maestro, aquí hay una versión corregida
[![Coverage Status](http://www.sbts.com.au/repos/github/ledgersmb/LedgerSMB/badge.svg?branch=master)](https://coveralls.io/github/ledgersmb/LedgerSMB?branch=master)


# LedgerSMB

Contabilidad de pequeñas y medianas empresas y ERP

# SINOPSIS

LedgerSMB es un sistema de contabilidad de aplicaciones web integrado y gratuito, presentando
contabilidad de doble entrada, presupuesto, facturación, cotizaciones, proyectos, tarjetas de tiempo,
manejador de inventario, envío y más ...

El UI permite accesibilidad en todo el mundo; con los datos almacenados en el
enterprise-strength PostgreSQL sistema de datos abierto, el sistema es conocido
para operar sin problemas para empresas con miles de transacciones por semana.
Las pantallas y la salida visible del cliente se definen en plantillas, permitiendo una facil y
rápida customziación. Los formatos de salida admitidos son PDF, CSV, HTML, ODF y más.

Envíe directamente órdenes y facturas desde la función de correo electrónico incorporada a tus
clientes o RFQs (request for quotation) a tus vendedores con archivos PDF.


# Requerimientos del sistema

## Servidor

 * Perl 5.14+
 * PostgreSQL 9.4+
 * Web server (e.j. nginx, Apache, lighttpd)

El servidor externo web solo se requiere para instalaciones de producción;
para fines de evaluación se puede usar una configuración más simple, como se detalla
abajo.

## Cliente

El [Dojo 1.12 compatible web browser](http://dojotoolkit.org/reference-guide/1.10/releasenotes/1.10.html#user-agent-support)
es todo lo que es requerido en el cliente (except IE8 and 9); Incluye Chrome en
su versión 13, FireFox en la 3.6 y MS Internet Explorer en la 10 y
una amplia gama de navegadores móviles.

# Inicio rápido

La manera más rápida para estar preparado es usar el Docker containers, así el proyecto
se hace disponible a través de Docker Hub.

Despues de prepar el Docker en este, inicia estos comandos para producir una preparación
de testeo

```sh
 $ docker pull ledgersmb/ledgersmb
 $ docker pull postgres
 $ mkdir -p /var/lib/pg-container/data
 $ docker run -d --name lsmb-postgres \
      -v /var/lib/pg-container/data:/var/lib/postgresql/data \
      -e POSTGRES_PASSWORD=<your secure password> \
      -e PGDATA=/var/lib/postgresql/data/pgdata  postgres
 $ docker run -d --name lsmb --link lsmb-postgres:postgres ledgersmb/ledgersmb
```

Los comandos de arriba inician automáticamente los contenedores.

Hay más variables de entorno disponibles para poder

 *correr la base de datos del PostgreSQL en un servidor diferente que el que está
   iniciando el contenedor de LedgerSMB 
 * configurar el correo electrónico saliente para enviar facturas, informes y otras salidas
  del contenedor
  
Ve la [documentación en el Docker Hub](https://hub.docker.com/r/ledgersmb/ledgersmb/).

# Inicio rápido (de la fuente)

Las instrucciones a continuación son para comenzar rápidamente desde la fuente; el [sitio del 
proyecyto](http://ledgersmb.org) proveé [instrucciones de instalación en profundidad](http://ledgersmb.org/topic/installing-ledgersmb-15)
para instalaciones de **produccion** .

## Ve las fuentes del GitHub

__***Omita este paso para instalaciones desde-tarball***__
(Instalación desde la versión de tarballs es preferible a la instalación de GitHub.)

Para obtener la última versión de desarrollo:

```sh
 $ git clone https://github.com/ledgersmb/LedgerSMB.git
 $ cd LedgerSMB
 $ git submodule update --init --recursive
```

Para obtener la versión 1.5.5, el comando debería de verse así:

```
 $ git clone -b 1.5.5 https://github.com/ledgersmb/LedgerSMB.git
 $ cd LedgerSMB
 $ git submodule update --init --recursive
```


## Dependencias del sistema (biblioteca)

El siguiente non-Perl (sistema) dependiente debe estar en su lugar para el comando
```cpanm``` mencionado a continuación para trabajar, además de lo que fue documentado
en la [como instalar modulos CPAN](http://www.cpan.org/modules/INSTALL.html)
página en CPAN.

 * cpanminus  Este se puede instalar manualmente o instalar como un paquete de sistema.
   No será necesario instalar cpanminus si solo vas a instalar desde paquetes Debian.
 * PostgreSQL librería de clientes
 * PostgreSQL servidor
 * DBD::Pg 3.4.2+ (el cpanm reconoce que no necesitará compilarlo)  
   Este paquete es llamado `libdbd-pg-perl` en Debian y `perl-DBD-Pg`
   en RedHat/Fedora
 * haz       Esto es utilizado por las dependencias de cpan durante su proceso de compilación

Entonces, algunas de las características enumeradas a continuación también tienen requisitos del sistema:

 * latex-pdf-ps depende de estos binarios o bibliotecas:
   * latex (generalmente se proporciona a través de un paquete texlive)
   * pdflatex
   * dvitopdf
   * dvitops
   * pdftops
 * latex-pdf-images
   * ImageMagick

## Dependencias del módulo Perl

Esta sección depende del [a working local::lib installation](https://ledgersmb.org/content/setting-perls-locallib-ledgersmb-why-and-how)
así como un ejecutable instalado `cpanm`. AMbos deberían estar disponibles en 
el repositorio de paquetes de su distribución (Debian los llama `liblocal-lib-perl`
y `cpanminus` respectivamente). `cpanm` depende que el comando `make` y `gcc` estén disponibles.

NOTA: gcc puede ser removido después de que todas las dependencias del cpan sean instaladas.
      Como sea, puede ser necesario reinstalarlo si se requieren módulos adicionales durante una actualización

PAra instalar el módulo de dependencias del Perl, incia:

```sh
 $ cpanm --quiet --notest --with-feature=starman [other features] --installdeps .

```
NOTA: No pierdas el "." al final del comando del cpanm!
No olvides asegurarte de que la variable de entorno `PERL5LIB=/home/ledgersmb/perl5/lib/perl5` apunte en el funcionamiento del usuario perl5 dir
DE igual forma, NUNCA inicies cpanm como root, es mejor ejecutarlo como el usuario que intenta ejecutar ledgersmb cuando sea posible.
Esto instala el modulo cpan en `~/perl5`
Si no puede ejecutarlo como el usuario final, no se preocupe, ejecutelo como cualqueir usuario (ej: johnny),
y asegúrese de que la variable de entorno `PERL5LIB=/home/johhny/perl5/lib/perl5` apunte hacia perl5 dir de jhonny

Poner la variable entorno de `PERL5` es hecho normalmente editando el script, o el archivo de servicio systemd.
Si lo está ejecutando manualmente, entonces necesitarás configurar y exportar `PERL5` antes de ejecutar starman/plack

Las siguientes características pueden ser seleccionadas
especificandolas ```--with-feature=<feature>```:

| Característica   | Descripción                                  |
|------------------|----------------------------------------------|
| latex-pdf-ps     | Habilita la salida de PDF y PostScript       |
| latex-pdf-images | Detección de tamaño de imagen para salida PDF|
| starman          | Starman Perl/PSGI servidor web               |
| openoffice       | OpenOffice.org documento de salida           |
| edi              | (EXPERIMENTAL) X12 EDI soporte               |
| xls              | Filtros de salida Excel (xls+xlsx)           |

Nota: El ejemplo de comando contiene ```--with-feature=starman``` para el
propocito del incio rápido.

Cuando no se instala como root o `sudo`, `cpanm` se instalará sin cumplirse las
dependencias de la biblioteca en una ubicación que se puede utilizar con `local::lib`. 

Las [instrucciones de instalación en profundidad](http://ledgersmb.org/topic/installing-ledgersmb-15)
contiene una lista de paquetes de distribución proporcionados para reducir el
número de dependencias instaladas por el CPAN.

**NOTAS**

 1. Para el objetivo pdf-ps, LaTeX es requerido.
 1. Para el objetivo pdf-images, ImageMagick es requerido.

## configuración del PostgreSQL 

Si bien es posible usar LedgerSMB con el usuario estándar del ```postgres```,
es una buena práctica crear una 'Administrador de la base de datos LedgerSMB':

```plain
$ sudo -u postgres createuser --no-superuser --createdb --login \
          --createrole --pwprompt lsmb_dbadmin
Enter password for new role: ****
Enter it again: ****
```

El archivo ```pg_hba.conf``` debe tener al menos estas líneas en él (el orden de las entradas importa):

```plain
local   all                            postgres                         peer
local   all                            all                              peer
host    all                            postgres        127.0.0.1/32     reject
host    all                            postgres        ::1/128          reject
host    postgres,template0,template1   lsmb_dbadmin    127.0.0.1/32     md5
host    postgres,template0,template1   lsmb_dbadmin    ::1/128          md5
host    postgres,template0,template1   all             127.0.0.1/32     reject
host    postgres,template0,template1   all             ::1/128          reject
host    all                            all             127.0.0.1/32     md5
host    all                            all             ::1/128          md5
```

 > Nota: `pg_hba.conf` puede ser encontrado en el `/etc/postgresql/<version>/main/` en Debian
 >  y en `/var/lib/pgsql/data/` en RedHat/Fedora

Después de editar el archivo ```pg_hba.conf```, recarga el servidor del PostgreSQL 
(o sin 'sudo' ejecutando los comandos como usuario root):

```sh
 $ sudo service postgresql reload
 # -or-
 $ sudo /etc/init.d/postgresql reload
```

## Configurar LedgerSMB

### Instalaciones desde-tarball
(La instalación desde tarball es muy preferible a la instalación desde GitHub para instalaciones de producción.)

```bash
 $ cp conf/ledgersmb.conf.default ledgersmb.conf
```

### Instalaciones de From-GitHub

```bash
 $ cp conf/ledgersmb.conf.unbuilt-dojo ledgersmb.conf
```

 > Nota: Usando 'built dojo' en vez de 'unbuilt dojo' mejorará en gran medida
 > tiempos de carga de páginas de algunas páginas.  Sin embargo, crear un built dojo
 > agrega considerable complejidad a estas instrucciones; por favor consulta
 > [the extensive setup instructions](https://ledgersmb.org/topic/installing-ledgersmb-15-github)
 > para build dojo.

## Ejecutar Starman

Con los pasos anteriores completados, el sistema está listo para ejecutar el servidor web:

 > NOTA: NO ejecutes starman (o cualquier  servicio web) como root, esto es considerado
 >     un serio problema de seguridad, y como tal LedgerSMB no lo admite.
 >     En cambio, si necesita iniciar LedgerSMB desde un proceso root, de
 >     privilegios a un usuario que no tiene acceso de escritura a los Directorios LedgerSMB primero.
 >     La mayoría de los mecanismos (ej: systemd) proveen un mecanismo para hacer esto.
 >     No use el mecanismo de starman --user=, actualmente proporciona los privilegios demasiado tarde.

```bash
 $ starman -I lib -I old/lib --listen localhost:5762 tools/starman.psgi
2016/05/12-02:14:57 Starman::Server (type Net::Server::PreFork) starting! pid(xxxx)
Resolved [*]:5762 to [::]:5762, IPv6
Not including resolved host [0.0.0.0] IPv4 because it will be handled by [::] IPv6
Binding to TCP port 5762 on host :: with IPv6
Setting gid to "1000 1000 24 25 27 29 30 44 46 108 111 121 1000"
```


## Variables de entorno

All regular Perl environment variables can be used. In particular, it's important to make sure
`PERL5LIB` is set correctly when setting up `local::lib` for the first time.

We support the following
- LSMB_WORKINGDIR : Opcional
     - Causa un chdir al directorio especificado como lo primero que se hace en starman.psgi
     - Si no se establece, se usa el directorio actual.
     - Un ejemplo podría ser 
    ```
    LSMB_WORKINGDIR='/usr/local/ledgersmb/'
    ```


## Siguientes pasos

El sistema está instalado y debería estar disponible para su evaluación a través de
- http://localhost:5762/setup.pl    # creación y gestión privilegiada de bases de datos de empresas
- http://localhost:5762/login.pl    # Inicio de sesión normal para la aplicación

El sistema está listo para la [preparacion del primer
uso](http://ledgersmb.org/topic/preparing/preparing-ledgersmb-15-first-use).

# Información del proyecto

Sitio web: [http://ledgersmb.org/](http://ledgersmb.org)

Chat en vivo:
 * IRC: [irc://irc.freenode.net/#ledgersmb](irc://irc.freenode.net/#ledgersmb)
 * Matrix: [https://vector.im/#/room/#ledgersmb:matrix.org](https://vector.im/#/room/#ledgersmb:matrix.org) (puente de canal IRC)

Foros: [http://forums.ledgersmb.org/](http://forums.ledgersmb.org/)

Archivos de la lista de correo: [http://archive.ledgersmb.org](http://archive.ledgersmb.org)

Listas de correo:
 * [https://lists.sourceforge.net/lists/listinfo/ledger-smb-announce](https://lists.sourceforge.net/lists/listinfo/ledger-smb-announce)
 * [https://lists.sourceforge.net/lists/listinfo/ledger-smb-users](https://lists.sourceforge.net/lists/listinfo/ledger-smb-users)
 * [https://lists.sourceforge.net/lists/listinfo/ledger-smb-devel](https://lists.sourceforge.net/lists/listinfo/ledger-smb-devel)

Repositorio: https://github.com/ledgersmb/LedgerSMB

## Contribuidores del proyecto

Los contribuidores del código fuente se pueden encontrar en el historial de confirmaciones de Git del proyecto
así como en el archivo CONTRIBUIDORES en el repositorio root.

Las contribuciones de traducción se pueden encontrar en el historial de commit de Git del proyecto
así como en la línea de tiempo del proyecto Transifex.


# Copyright

```plain
Copyright (c) 2006 - 2017 The LedgerSMB Project contributors
Copyright (c) 1999 - 2006 DWS Systems Inc (under the name SQL Ledger)
```

# License

[GPLv2](http://open-source.org/licenses/GPL-2.0)
