describe('Collection', () => {

  before(() => {
    cy.login();
    cy.create_token();
    cy.create_organization('test-organization-collection', 'Test Organization Collection');
    cy.fixture('child_dataset.json').then((child_dataset) => {
      cy.create_dataset(child_dataset).should((response) => {
          expect(response.body).to.have.property('success', true);
      });
    });
    cy.fixture('parent_dataset.json').then((parent_dataset) => {
      cy.create_dataset(parent_dataset).should((response) => {
          expect(response.body).to.have.property('success', true);
      });
    });
  });

  after(() => {
    // cy.delete_dataset('child');
    // cy.delete_dataset('parent');
    // cy.delete_organization('test-organization');
    cy.revoke_token();
    cy.logout();
  });

  it('Has a UI search button', () => {
      cy.visit('/dataset/parent');
      cy.hide_debug_toolbar();
      // Click on the "Search within this collection" button
      cy.contains('Search datasets within this collection').click();
      // TODO: Check the collection info in the top of the page
      cy.url().should('include', 'collection_info=harvest-source+pid');
      cy.contains('1 dataset found');
  });
});
