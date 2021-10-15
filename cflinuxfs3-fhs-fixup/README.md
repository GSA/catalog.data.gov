# How to restore missing FHS directories in cflinuxfs3

When the cflinuxfs3 filesystem is created, [certain commonly assumed directories are removed](https://github.com/cloudfoundry/cflinuxfs3/blob/7ee887669476246b7eb05a3ee5b5b5eeba163c22/Dockerfile#L19-L22). This can cause misconfiguration problems if you try to install packages that expect those directories to be there (eg `default-jre-headless` which provides the `java` CLI).

Here's a solution that addresses this problem for non-operators of Cloud Foundry:

1. Create a .deb package that will undo the damage
    ```
    make madness
    ```
2. Host the resulting .deb file somewhere
3. Reference that .deb file in your `apt.yml` file
    ```
    ---
    packages:
    - https://the-host-for-your-package/path/to/the/package.deb
    - <any other packages>
    ```
4. Add [the apt-buildpack](https://github.com/cloudfoundry/apt-buildpack) to the [`buildpacks:` list in your manifest.yml](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest-attributes.html#buildpack) (but not as the final one in your list!) 

    Alternatively, explicitly specify the list of buildpacks with `-b https://github.com/cloudfoundry/apt-buildpack -b _otherbuildpack_` in your `cf push` command.