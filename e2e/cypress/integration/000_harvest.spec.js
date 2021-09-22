describe('Harvest', () => {
    // Rename this only if necessary, various test dependencies
    const harvestOrg = 'test-harvest-org'
    const dataJsonHarvestSoureName = 'test-harvest-datajson'
    const wafIsoHarvestSourceName = 'test-harvest-waf-iso'
    const cswHarvestSoureName = 'test-harvest-csw'

    before(() => {
        /**
         * Login as cypress user and create an organization for testing harvest source creation and running the jobs
         */
        cy.login()
        // Make sure organization does not exist before creating
        cy.delete_organization(harvestOrg)
        // Create the organization
        cy.create_organization(harvestOrg, 'cypress harvest org description', false)
    })
    beforeEach(() => {
        /**
         * Preserve the cookies to stay logged in
         */
        Cypress.Cookies.preserveOnce('auth_tkt', 'ckan')
    })
    after(() => {
        /**
         * Do not clear harvest sources so other tests can
         * evaluate the created datasets
         */
        // cy.delete_harvest_source(wafIsoHarvestSourceName)
        // cy.delete_harvest_source(dataJsonHarvestSoureName)
        // cy.delete_organization(harvestOrg)
    })

    it('Create datajson Harvest Source VALID', () => {
        /**
         * Test creating a valid datajson harvest source
         */
        //cy.get('a[href="/organization/edit/'+harvestOrg+'"]').click()
        cy.visit(`/organization/${harvestOrg}`)
        cy.get('a[class="btn btn-primary"]').click()
        cy.get('a[href="/harvest?organization='+harvestOrg+'"]').click()
        cy.get('a[class="btn btn-primary"]').click()
        cy.create_harvest_source('http://nginx-harvest-source/data.json',
                        dataJsonHarvestSoureName,
                        'cypress test datajson',
                        'datajson',
                        'False',
                        false)

        // harvestTitle must not contain spaces, otherwise the URL redirect will not confirm
        cy.location('pathname').should('eq', '/harvest/' + dataJsonHarvestSoureName)
    })

    it('Create a datajson harvest source INVALID', () => {
        cy.visit('/organization/'+harvestOrg)
        // Hide flask debug toolbar
        cy.get('#flHideToolBarButton').click();

        cy.get('a[class="btn btn-primary"]').click()
        cy.get('a[href="/harvest?organization='+harvestOrg+'"]').click()
        cy.get('a[class="btn btn-primary"]').click()
        cy.create_harvest_source('😀',
                        'invalid datajson',
                        'invalid datajson',
                        'datajson',
                        'False',
                        true)
        cy.contains('URL: Missing value')
    })

    it('Search harvest source', () => {
        cy.visit('/harvest')
        cy.get('#field-giant-search').type('datajson')
        cy.contains('1 harvest found')
    })

    it('Reharvest datajson Harvest Job', () => {
        cy.wait(5000)
        cy.start_harvest_job(dataJsonHarvestSoureName)
    })

    it('Create WAF ISO Harvest Source', () => {
        /**
         * Create a WAF ISO Harvest Source
         */
        cy.visit('/organization/'+harvestOrg)
        // Hide flask debug toolbar
        cy.get('#flHideToolBarButton').click();

        cy.get('a[class="btn btn-primary"]').click()
        cy.get('a[href="/harvest?organization='+harvestOrg+'"]').click()
        cy.get('a[class="btn btn-primary"]').click()
        cy.create_harvest_source('http://nginx-harvest-source/iso-waf/',
           wafIsoHarvestSourceName,
           'cypress test waf iso',
           'waf',
           'False',
           false)
        // harvestTitle must not contain spaces, otherwise the URL redirect will not confirm
        cy.location('pathname').should('eq', '/harvest/' + wafIsoHarvestSourceName)
    })

    it('Keeps the Dataset visilibity flag', () => {
        // Go to previously created harvest source
        cy.visit(`/harvest/edit/${wafIsoHarvestSourceName}`)

        cy.get('#field-private_datasets').find(':selected').contains('Public')
    })

    it('Start WAF ISO Harvest Job', () => {

        cy.start_harvest_job(wafIsoHarvestSourceName)
    })

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
        cy.visit(`/organization/${harvestOrg}`)
        cy.get('a[class="btn btn-primary"]').click()
        cy.get('a[href="/harvest?organization='+harvestOrg+'"]').click()
        cy.get('a[class="btn btn-primary"]').click()
        cy.create_harvest_source('https://portal.opentopography.org/geoportal/csw',
                        cswHarvestSoureName,
                        'cypress test csw',
                        'csw',
                        'False',
                        false)

        // harvestTitle must not contain spaces, otherwise the URL redirect will not confirm
        cy.location('pathname').should('eq', '/harvest/' + cswHarvestSoureName)
    })

    it('Start CSW Harvest Job', () => {
        cy.start_harvest_job(cswHarvestSoureName)
    })
})