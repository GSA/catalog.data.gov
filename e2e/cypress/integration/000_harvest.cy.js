describe('Harvest', { testIsolation: false }, () => {
    // Rename this only if necessary, various test dependencies
    const harvestOrg = 'test-harvest-org';
    const dataJsonHarvestSoureName = 'test-harvest-datajson';
    const wafIsoHarvestSourceName = 'test-harvest-waf-iso';
    const wafFgdcHarvestSourceName = 'test-harvest-waf-fgdc';
    const cswHarvestSourceName = 'test-harvest-csw';

    before(() => {
        /**
         * Login as cypress user and create an organization for testing harvest source creation and running the jobs
         */
        cy.login();
        // Make sure organization does not exist before creating
        cy.delete_organization(harvestOrg);
        // Create the organization
        cy.create_organization(harvestOrg, 'cypress harvest org description', false);
    });

    after(() => {
        cy.logout();
        /**
         * Do not clear harvest sources so other tests can
         * evaluate the created datasets
         */
        // cy.delete_harvest_source(wafIsoHarvestSourceName)
        // cy.delete_harvest_source(dataJsonHarvestSoureName)
        // cy.delete_organization(harvestOrg)
    });

    it('Create datajson Harvest Source VALID', () => {
        /**
         * Test creating a valid datajson harvest source
         */
        cy.create_harvest_source(
            harvestOrg,
            'http://nginx-harvest-source/data.json',
            dataJsonHarvestSoureName,
            'cypress test datajson',
            'datajson',
            'False',
            false
        );

        // harvestTitle must not contain spaces, otherwise the URL redirect will not confirm
        cy.location('pathname').should('eq', '/harvest/' + dataJsonHarvestSoureName);
    });

    it('Create a datajson harvest source INVALID', () => {
        cy.create_harvest_source(harvestOrg, '😀', 'invalid datajson', 'invalid datajson', 'datajson', 'False', true);
        cy.contains('URL: Missing value');
    });

    it('Search harvest source', () => {
        cy.visit('/harvest');
        cy.get('#field-giant-search').type('datajson');
        cy.contains('1 harvest found');
    });

    it('Reharvest datajson Harvest Job', () => {
        cy.wait(5000);
        cy.start_harvest_job(dataJsonHarvestSoureName);
        cy.check_dataset_harvested(5);
    });

    it('Create WAF ISO Harvest Source', () => {
        /**
         * Create a WAF ISO Harvest Source
         */
        cy.create_harvest_source(
            harvestOrg,
            'http://nginx-harvest-source/iso-waf/',
            wafIsoHarvestSourceName,
            'cypress test waf iso',
            'waf',
            'False',
            false
        );
        // harvestTitle must not contain spaces, otherwise the URL redirect will not confirm
        cy.location('pathname').should('eq', '/harvest/' + wafIsoHarvestSourceName);
    });

    it('Keeps the Dataset visilibity flag', () => {
        // Go to previously created harvest source
        cy.visit(`/harvest/edit/${wafIsoHarvestSourceName}`);

        cy.get('#field-private_datasets').find(':selected').contains('Public');
    });

    it('Start WAF ISO Harvest Job', () => {
        cy.start_harvest_job(wafIsoHarvestSourceName);
        cy.check_dataset_harvested(5);
    });

    it('Create WAF FGDC Harvest Source', () => {
        /**
         * Create a WAF ISO Harvest Source
         */
        cy.create_harvest_source(
            harvestOrg,
            'http://nginx-harvest-source/fgdc-waf/',
            wafFgdcHarvestSourceName,
            'cypress test waf FGDC',
            'waf',
            'False',
            false
        );
        // harvestTitle must not contain spaces, otherwise the URL redirect will not confirm
        cy.location('pathname').should('eq', '/harvest/' + wafFgdcHarvestSourceName);
    });

    it('Start WAF FGDC Harvest Job', () => {
        cy.start_harvest_job(wafFgdcHarvestSourceName);
        cy.check_dataset_harvested(5);
    });

    it('Create CSW Harvest Source', () => {
        /**
         * Test creating a valid csw harvest source.
         * Mocking a CSW harvest source is extremely complex,
         * we took a shortcut and used a public endpoint.
         * This test may fail in the future due to removal of
         * the service not under our control, at that point we should
         * remove the test or create a CSW service locally.
         * Currently only 1 harvest endpoint is working for data.gov,
         * so testing that use case seems appropriate. You can check
         * how many harvest sources are created for CSW by going to
         * https://catalog.data.gov/harvest?source_type=csw
         */

        cy.create_harvest_source(
            harvestOrg,
            'https://portal.opentopography.org/geoportal/csw',
            cswHarvestSourceName,
            'cypress test csw',
            'csw',
            'False',
            false
        );

        // harvestTitle must not contain spaces, otherwise the URL redirect will not confirm
        cy.location('pathname').should('eq', '/harvest/' + cswHarvestSourceName);
    });

    it('Start CSW Harvest Job', () => {
        cy.start_harvest_job(cswHarvestSourceName);
        cy.check_dataset_harvested(5);
    });
});
