describe('Prepare', { testIsolation: false }, () => {
    const testOrgName = 'Test Organization';
    const testOrgId = 'test-organization';
    const testOrgDesc = 'cypress test org description';

    before(() => {
        /**
         * Login as cypress user and create an organization
         */
        cy.login();

        // Create the Test Organization using UI
        cy.visit('/organization');
        cy.get('a[class="btn btn-primary"]').click();
        cy.create_organization_ui(testOrgName, testOrgDesc);

        // Create the Test Dataset
        cy.create_dataset();
    });

    after(() => {
        cy.logout();
        cy.delete_dataset();
        cy.delete_organization();
    });

    it('Test Org is created', () => {
        // can visit the org using testOrgId 
        cy.visit('/organization/' + testOrgId);
        cy.contains(testOrgName);
        cy.contains(testOrgDesc);
    });

    it('Test Dataset is created', () => {
        cy.visit('/dataset/test-dataset');
        cy.contains('Test Dataset');
    });
});
