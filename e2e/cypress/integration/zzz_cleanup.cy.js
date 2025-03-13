describe('Cleanup site', () => {
    const harvestOrg = 'test-harvest-org';
    const dataJsonHarvestSoureName = 'test-harvest-datajson';
    const wafIsoHarvestSourceName = 'test-harvest-waf-iso';
    const wafFgdcHarvestSourceName = 'test-harvest-waf-fgdc';
    // const cswHarvestSourceName = 'test-harvest-csw'; TODO: delete

    before(() => {
        cy.login();

        // Clear and remove all harvested data
        cy.delete_harvest_source(dataJsonHarvestSoureName);
        cy.delete_harvest_source(wafIsoHarvestSourceName);
        cy.delete_harvest_source(wafFgdcHarvestSourceName);
        // cy.delete_harvest_source(cswHarvestSourceName); TODO: delete

        // Sometimes things are left in the DB locally, you can use this to delete 1-off datasets
        // cy.delete_dataset("invasive-plant-prioritization-for-inventory-and-early-detection-at-guadalupe-nipomo-dunes-");

        // Make sure DB is fully cleared
        cy.wait(3000);
        // Remove organization
        cy.delete_organization(harvestOrg);
    });

    after(() => {
        cy.logout();
    });

    it('Confirms empty site', () => {
        cy.visit('/dataset');
        cy.contains('No datasets found');
        cy.visit('/organization');
        cy.contains('No organizations found');
    });
});
