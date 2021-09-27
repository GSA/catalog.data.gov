describe('Cleanup site', () => {
    const harvestOrg = 'test-harvest-org'
    const dataJsonHarvestSoureName = 'test-harvest-datajson'
    const wafIsoHarvestSourceName = 'test-harvest-waf-iso'
    const cswHarvestSourceName = 'test-harvest-csw'

    before(() => {
        /**
         * Login as cypress user and create an organization for testing harvest source creation and running the jobs
         */
        cy.login()

        // Clear and remove all harvested data
        cy.delete_harvest_source(dataJsonHarvestSoureName);
        cy.delete_harvest_source(wafIsoHarvestSourceName);
        cy.delete_harvest_source(cswHarvestSourceName);

        // Sometimes things are left in the DB locally, you can use this to delete 1-off datasets
        // cy.delete_dataset("invasive-plant-prioritization-for-inventory-and-early-detection-at-guadalupe-nipomo-dunes-");

        // Make sure DB is fully cleared
        cy.wait(3000);

        // Remove organization
        cy.delete_organization(harvestOrg)
    })

    it('Confirms empty site', () => {
        cy.visit('/dataset');
        cy.contains("No datasets found");
        cy.visit('/organization');
        cy.contains("No organizations found");
    })
})