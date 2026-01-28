# :world_map: Internet-in-a-Box en Android

**[Internet-in-a-Box (IIAB)](https://internet-in-a-box.org) en Android** permitirá que millones de personas en todo el mundo construyan sus propias bibliotecas familiares, ¡dentro de sus propios teléfonos!

A Enero de 2026, estas Apps de IIAB están soportadas:

* **Calibre-Web** (eBooks & videos)
* **Kiwix** (Wikipedias, etc)
* **Kolibri** (lecciones y cuestionarios)
* **Maps** (fotos satelitales, relieve, edificios)
* **Matomo** (métricas)

El puerto predeterminado del servidor web es **8085**, por ejemplo:

```
http://localhost:8085/maps
```

## ¿Cuáles son los componentes actuales de "IIAB en Android"?

* **[termux-setup](https://github.com/iiab/iiab-android/tree/main/termux-setup) (iiab-termux)** — prepara un entorno tipo Debian en Android (se llama [PRoot](https://wiki.termux.com/wiki/PRoot))
* **Wrapper para instalar IIAB (iiab-android)** — configura [`local_vars_android.yml`](https://github.com/iiab/iiab/blob/master/vars/local_vars_android.yml) y luego lanza el instalador de IIAB
* **Capa principal de portabilidad de IIAB** — modificaciones a través de IIAB y sus roles existentes, basado en el [PR #4122](https://github.com/iiab/iiab/pull/4122)
* **proot-distro service manager (PDSM)** — como systemd, pero para `proot_services`

## Documentación relacionada

* **Bootstrap de Android (en este repo):** [`termux-setup/README.md`](https://github.com/iiab/iiab-android/blob/main/termux-setup/README.md)
* **Rol proot_services (en el repo principal de IIAB):** [`roles/proot_services/README.md`](https://github.com/iiab/iiab/blob/master/roles/proot_services/README.md)

---

## :clipboard: Guía de instalación

1. Empieza con un teléfono o tablet Android 9 o superior:

   * Instala **F-Droid**. Será nuestra fuente principal de apps requeridas y actualizaciones. Como extra, no hace falta abrir una cuenta.
     * [https://f-droid.org/F-Droid.apk](https://f-droid.org/F-Droid.apk)
     * Tendrás que permitir "instalar desde fuentes desconocidas" (o "instalar apps desconocidas") desde Chrome

   * Actualiza los **repositorios de F-Droid**.
     * Abre la app F-Droid y pulsa "Avisos" (Actualizaciones).
   * Busca **Termux** e instala:
     * **Termux** Emulador de terminal con paquetes (com.termux)
     * **Termux:API** Acceso a funciones de Android desde Termux (com.termux.api)
     * Tendrás que permitir "Instalar desde fuentes desconocidas" (o "Instalar apps desconocidas") desde F-Droid

   **Nota**: Puede que veas la etiqueta "*Esta aplicación se creó para una versión anterior de Android y no se puede actualizar automáticamente.*" en ambas apps. Puedes ignorarlo, ya que solo se refiere a la función de [*auto-update*](https://f-droid.org/en/2024/02/01/twif.html). Las actualizaciones manuales seguirán funcionando. [Lee más aquí](https://github.com/termux/termux-packages/wiki/Termux-and-Android-10/3e8102ecd05c4954d67971ff2b508f32900265f7).

2. Habilita **Opciones de desarrollador** en Android:

   * En **Ajustes > Acerca del dispositivo** (o **Acerca de la tablet**, o **Información de Software**), encuentre **Número de compilación** (o **Número de versión**), y tócala siete veces rápidamente.

3. Prepara el entorno de Termux. Android 12 y versiones posteriores tienen una función llamada ["Phantom Process Killer" (PPK)](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md), que limita la cantidad de procesos hijo. Necesitamos desactivar esta restricción para ejecutar IIAB correctamente. En Android 12 y 13, desactivarás PPK como parte de la configuración del entorno Termux ya que no existe opción en la UI. Para Android 14+, puedes desactivar la restricción usando Ajustes de Android (ver abajo).

   En todas las versiones de Android, ejecuta lo siguiente:

   ```
   curl iiab.io/termux.txt | bash
   ```

   * En Android 12 y 13, asegúrate de aceptar los pasos de ADB Pair/Connect cuando se te solicite. Se te pedirán 3 valores: **Connect Port**, **Pair Port** y **Pair Code**. Por favor revisa este (WIP) [video tutorial](https://ark.switnet.org/vid/termux_adb_pair_a16_hb.mp4) para una explicación más interactiva. Una vez conectado a ADB, el script `iiab-termux` se encargará de la configuración del workaround de PPK.

   * En Android 14 y posteriores: desactiva esta restricción usando Ajustes de Android, en **Opciones de desarrollador**:

     * `Inhabilitar restricciones de procesos secundarios`, o
     * `Desactivar restricciones de procesos secundarios`

   * **Uso de batería**: Para ejecutar el instalador de IIAB en Android, o mantener los servicios de IIAB corriendo en segundo plano (pantalla apagada), debes permitir que Termux se ejecute sin restricciones de batería. Dependiendo de tu dispositivo y versión de Android, este ajuste puede aparecer como alguno de los siguientes:

     * No restringido
     * No optimizar / Sin optimizar
     * Permitir actividad/uso en segundo plano

     La etiqueta exacta varía según el fabricante y la versión de Android. Asegúrate de habilitarlo para instalaciones desatendidas con pantalla apagada; de lo contrario Android puede entrar en "reposo", pausar o incluso terminar el proceso cuando la pantalla se apaga.

     Dejar esto habilitado es la forma más confiable de mantener la app y los servicios ejecutándose y listos. Ten en cuenta que el consumo de batería aumentará, así que conviene mantener un cargador cerca.


5. Entra a la distro IIAB Debian de [PRoot Distro](https://wiki.termux.com/wiki/PRoot) para continuar la instalación:

   ```
   iiab-termux --login
   ```

6. Ejecuta `iiab-android`, que (a) instala `local_vars_android.yml` en [`/etc/iiab/local_vars.yml`](https://wiki.iiab.io/go/FAQ#What_is_local_vars.yml_and_how_do_I_customize_it?) y después (b) ejecuta el instalador de IIAB:

   ```
   iiab-android
   ```

   Si el instalador termina correctamente, verás un cuadro de texto que dice:

   > INTERNET-IN-A-BOX (IIAB) SOFTWARE INSTALL IS COMPLETE

## Probar tu instalación de IIAB

Los [servicios `pdsm`](https://github.com/iiab/iiab/tree/master/roles/proot_services) de IIAB inician automáticamente después de la instalación. Para verificar que tus Apps de IIAB están funcionando (usando un navegador en tu dispositivo Android) visita estas URLs:

| App                    | URL                                                            |
|------------------------|----------------------------------------------------------------|
| Calibre-Web            | [http://localhost:8085/books](http://localhost:8085/books)     |
| Kiwix (for ZIM files!) | [http://localhost:8085/kiwix](http://localhost:8085/kiwix)     |
| Kolibri                | [http://localhost:8085/kolibri](http://localhost:8085/kolibri) |
| IIAB Maps              | [http://localhost:8085/maps](http://localhost:8085/maps)       |
| Matomo                 | [http://localhost:8085/matomo](http://localhost:8085/matomo)   |

Si encuentras un error o problema, por favor abre una [incidencia](https://github.com/iiab/iiab/issues) para que podamos ayudarte (y ayudar a otros) lo más rápido posible.

### Agregar un archivo ZIM

¡Ahora puedes poner una copia de Wikipedia (en casi cualquier idioma) en tu teléfono o tablet Android! Aquí te decimos cómo…

1. Navega al sitio: [download.kiwix.org/zim](https://download.kiwix.org/zim/)
2. Elige un archivo `.zim` (archivo ZIM) y copia su URL completa, por ejemplo:

   ``` 
   https://download.kiwix.org/zim/wikipedia/wikipedia_es_top_mini_2025-09.zim
   ```

3. Abre la app Termux de Android y luego ejecuta:

   ```
   iiab-termux --login
   ```

   EXPLICACIÓN: Desde la línea de comandos (CLI, Command-Line Interface) de alto nivel de Termux, has "entrado vía shell" a la linea de comandos de bajo nivel de IIAB Debian en [PRoot Distro](https://wiki.termux.com/wiki/PRoot):

   ```
          +----------------------------------+
          | Interfaz Android (Apps, Ajustes) |
          +-----------------+----------------+
                            |
                   abrir la | app Termux
                            v
              +-------------+------------+
              |   Termux (Android CLI)   |
              | $ iiab-termux --login    |
              +-------------+------------+
                            |
      "entrar vía shell" al | entorno de bajo nivel
                            v
      +---------------------+---------------------+
      |   proot-distro: IIAB Debian (userspace)   |
      | debian root# cd /opt/iiab/iiab            |
      +-------------------------------------------+
   ```

4. Entra a la carpeta donde IIAB guarda los archivos ZIM:

   ```
   cd /library/zims/content/
   ```

5. Descarga el archivo ZIM usando la URL que elegiste arriba, por ejemplo:

   ```
   wget https://download.kiwix.org/zim/wikipedia/wikipedia_es_top_mini_2025-09.zim
   ```

6. Cuando termine la descarga, re-indexa los archivos ZIM de IIAB: (para que el nuevo ZIM aparezca para los usuarios, en la página http://localhost:8085/kiwix)

   ```
   iiab-make-kiwix-lib
   ```

   TIP: Repite este último paso cuando elimines o agregues nuevos archivos ZIM en `/library/zims/content/`

## Acceso remoto

Aunque el teclado y la pantalla del teléfono son prácticos cuando estás en movimiento, acceder al entorno IIAB Debian de PRoot Distro desde una PC o laptop es muy útil para depuración. Puedes usar una conexión Wi-Fi existente o habilitar el hotspot nativo de Android si no hay una LAN inalámbrica disponible.

Antes de comenzar, obtén la IP de tu teléfono o tablet Android ejecutando `ifconfig` en Termux. O bien, obtén la IP revisando **Acerca del dispositivo → Estado** en los Ajustes de Android.

### SSH

Para iniciar sesión en IIAB en Android desde tu computadora, sigue estas instrucciones en CLI (línea de comandos) con SSH:

1. En tu teléfono o tablet Android, llega al CLI de Termux. **Si antes ejecutaste `iiab-termux --login` para entrar al CLI de bajo nivel de IIAB Debian en PRoot Distro — DEBES regresar al CLI de alto nivel de Termux — por ejemplo ejecutando:**

   ```
   exit
   ```

2. La forma más rápida de entrar por SSH a tu teléfono (o tablet) Android es poner una contraseña para el usuario de Termux. En el CLI de alto nivel de Termux, ejecuta:

   ```
   passwd
   ```

   Opcionalmente, la seguridad puede mejorar usando autenticación estándar por llaves SSH mediante el archivo `~/.ssh/authorized_keys`.

3. Inicia el servicio SSH. En la linea de comandos de alto nivel de Termux, ejecuta:

   ```
   sshd
   ```

   El servicio `sshd` puede automatizarse para iniciar cuando Termux se abre (ver [Termux-services](https://wiki.Termux.com/wiki/Termux-services)). Recomendamos hacer esto solo después de mejorar la seguridad de inicio de sesión usando llaves SSH.

4. Conéctate por SSH a tu teléfono Android.

   Desde tu laptop o PC, conectada a la misma red que tu teléfono Android, y conociendo la IP del teléfono (por ejemplo, `192.168.10.100`), ejecutarías:

   ```
   ssh -p 8022 192.168.10.100
   ```

   ¡No se necesita un nombre de usuario!

   Nota que el puerto **8022** se usa para SSH. Como Android se ejecuta sin permisos root, SSH no puede usar puertos con números menores. (Por la misma razón, el servidor web de IIAB [nginx] usa el puerto **8085** en lugar del puerto 80.)

### Iniciar sesión en el entorno de IIAB

Una vez que tengas una sesión SSH en tu dispositivo remoto, entra a PRoot Distro para acceder y ejecutar las aplicaciones de IIAB, igual que durante la instalación:

```
iiab-termux --login
```

Entonces estarás en una shell IIAB Debian con acceso a las herramientas del CLI (linea de comandos) de IIAB.

## Eliminación

Si quieres eliminar la instalación de IIAB y todas las apps asociadas, sigue estos pasos:

1. Elimina la instalación de IIAB que corre en PRoot Distro:

   ```
   proot-distro remove iiab
   ```

   **Nota:** Todo el contenido en esa instalación de IIAB se borrará al ejecutar este comando. Respaldar tu contenido primero si planeas reinstalar después.

2. Desinstala ambas apps, Termux y Termux-API, si ya no las necesitas.

3. Deshabilita Opciones de desarrollador.
