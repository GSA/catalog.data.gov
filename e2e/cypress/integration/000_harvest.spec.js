describe('Harvest', () => {
    // Rename this only if necessary, various test dependencies
    const harvestOrg = 'cypress-harvest-org'
    const dataJsonHarvestSoureName = 'test-harvest-datajson'
    const wafIsoHarvestSourceName = 'cypress-harvest-waf-iso'

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
         * Do not clear harvest sources so other tests can use
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
                        harvestOrg,
                        true,
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
                        harvestOrg,
                        true,
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
        cy.create_harvest_source('https://www.sciencebase.gov/data/lcc/california/iso2/',
           wafIsoHarvestSourceName,
           'cypress test waf iso',
           'waf',
           harvestOrg,
           true,
           false)
        // harvestTitle must not contain spaces, otherwise the URL redirect will not confirm
        cy.location('pathname').should('eq', '/harvest/' + wafIsoHarvestSourceName)
    })

    it('Start WAF ISO Harvest Job', () => {

        cy.start_harvest_job(wafIsoHarvestSourceName)
    })
})