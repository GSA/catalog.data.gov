describe('Collection', () => {

    const orgId = "org-" + cy.helpers.randomSlug();
    const parentId = "parent-" + orgId;
		const childId = "child-" + parentId;

    before(() => {
      cy.login();
      cy.create_token();
      cy.create_organization(orgId);
      cy.create_dataset({
        "name": parentId,
        "owner_org": orgId,
				"extras": [
					{
						"key": "Identifier",
						"value": parentId
					},
					{
						"key": "harvest_source_id",
						"value": "harvest-source"
					}
				]
      });
      cy.create_dataset({
        "name": childId,
        "owner_org": orgId,
				"extras": [
					{
						"key": "isPartOf",
						"value": parentId
					},
					{
						"key": "harvest_source_id",
						"value": "harvest-source"
					}
				]
      });
    });

    after(() => {
      cy.delete_dataset(childId);
      cy.delete_dataset(parentId);
      cy.delete_organization(orgId);
    });

    it('Has a UI search button', () => {
        cy.visit('/dataset/' + parentId);
        cy.hide_debug_toolbar();
        // Click on the "Search within this collection" button
        cy.contains('Search datasets within this collection').click();
        cy.url().should('include', '?collection_info');
    });
});
