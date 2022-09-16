describe('CKAN Extensions', () => {
    it('Uses CKAN 2.9', () => {
        cy.request('/api/action/status_show').should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result).to.have.property('ckan_version', '2.9.5');
        });
    });

    it('Has all necessary extensions installed', () => {
        cy.request('/api/action/status_show').should((response) => {
            expect(response.body).to.have.property('success', true);
            const installed_extensions = response.body.result.extensions;
            expect(installed_extensions).to.include('envvars');
            expect(installed_extensions).to.include('image_view');
            expect(installed_extensions).to.include('text_view');
            expect(installed_extensions).to.include('recline_view');
            expect(installed_extensions).to.include('ckan_harvester');
            expect(installed_extensions).to.include('datajson_harvest');
            expect(installed_extensions).to.include('datagovtheme');
            expect(installed_extensions).to.include('datagov_harvest');
            expect(installed_extensions).to.include('geodatagov');
            expect(installed_extensions).to.include('geodatagov_miscs');
            expect(installed_extensions).to.include('z3950_harvester');
            expect(installed_extensions).to.include('arcgis_harvester');
            expect(installed_extensions).to.include('geodatagov_geoportal_harvester');
            expect(installed_extensions).to.include('waf_harvester_collection');
            expect(installed_extensions).to.include('geodatagov_csw_harvester');
            expect(installed_extensions).to.include('geodatagov_doc_harvester');
            expect(installed_extensions).to.include('geodatagov_waf_harvester');
            expect(installed_extensions).to.include('spatial_metadata');
            expect(installed_extensions).to.include('spatial_query');
            expect(installed_extensions).to.include('spatial_harvest_metadata_api');
            expect(installed_extensions).to.include('googleanalyticsbasic');
            expect(installed_extensions).to.include('dcat');
            expect(installed_extensions).to.include('dcat_json_interface');
            expect(installed_extensions).to.include('structured_data');
            expect(installed_extensions).to.include('datagovcatalog');
            expect(installed_extensions).to.include('report');
            expect(installed_extensions).to.include('archiver');

            // TODO: The following extensions should be verified to be installed:
            // expect(installed_extensions).to.include('qa');
        });
    });
});
