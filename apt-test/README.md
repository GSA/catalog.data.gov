## How to test that this sample is working

1. Copy the `vars.yml-template` file to `vars.yml`, then edit it to insert your name.
2. Run

    ```bash
    cf push --vars-file vars.yml
    ```

3. SSH in, taking care to ensure the `.profile` is run just as it is for the app itself:

    ```bash
    cf ssh apt-test-yourname  -t -c "/tmp/lifecycle/launcher /home/vcap/app bash ''"
    ```

4. Try the sample:

    ```bash
    java -cp ./saxon.jar net.sf.saxon.Transform -s:fgdc-csdgm_sample.xml -xsl:fgdcrse2iso19115-2.xslt -o:iso_sample.xml
    ```

You should see no errors, and find a valid XML file in `iso_sample.xml`.
