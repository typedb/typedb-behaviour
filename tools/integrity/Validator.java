/*
* Copyright (C) 2020 Grakn Labs
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

package grakn.verification.tools.integrity;

import grakn.client.GraknClient;
import grakn.client.answer.ConceptMap;
import grakn.client.concept.Label;
import grakn.client.concept.SchemaConcept;
import grakn.common.util.Pair;
import grakn.verification.tools.integrity.schema.Has;
import grakn.verification.tools.integrity.schema.Plays;
import grakn.verification.tools.integrity.schema.Relates;
import grakn.verification.tools.integrity.schema.Sub;
import grakn.verification.tools.integrity.schema.TransitiveSub;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

public class Validator {

    private static final Logger LOG = LoggerFactory.getLogger(Validator.class);

    /*
    TODO
    In general, we have the issue of ignoring inherited pairs when trying to build the
    non-transitive sets.
    Transitive sets will be built up later
     */

    public enum META_TYPES {
        THING("thing"),
        ENTITY("entity"),
        RELATION("relation"),
        ATTRIBUTE("attribute");

        private String name;
        META_TYPES(String name) { this.name = name; }
        public String getName() { return name; }
    }

    private GraknClient.Session session;

    public Validator(GraknClient.Session session) {
        this.session = session;
    }

    public boolean validate() {
        RejectDuplicateSet<Type> types = createAndValidateTypes();
        RejectDuplicateSet<Type> roles = createAndValidateRoles(); // TODO figure out how we want to deal with roles, esp role inheritance
        Sub sub = createAndValidateSub(types);
        TransitiveSub transitiveSub = createAndValidateTransitiveSubWithoutIdentity(sub);

        RejectDuplicateSet<Type> entities = createEntityTypes(transitiveSub);
        RejectDuplicateSet<Type> relations = createRelationTypes(transitiveSub);
        RejectDuplicateSet<Type> attributes = createAttributeTypes(transitiveSub);

        Has has = createAndValidateHas(types, attributes);
        Has key = createAndValidateKey(types, attributes, has);

        Plays plays = createAndValidatePlays(types, roles);
        Relates relates = createAndValidateRelates(relations, roles);
        validatePlaysAndRelatesOverlap(plays, relates);

        RejectDuplicateSet<Type>  abstractTypes = createAndValidateAbstractTypes(types);

        return true;
    }


    void validatePlaysAndRelatesOverlap(Plays plays, Relates relates) {
        // every role that is played must be related
        for (Pair<Type, Type> playsRole : plays) {
            boolean found = false;
            for (Pair<Type, Type> relatesRole : relates) {
                if (playsRole.second().equals(relatesRole.second())) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                throw IntegrityException.playedRoleIsNotRelated(playsRole.second(), playsRole.first());
            }
        }
    }

    RejectDuplicateSet<Type> createAndValidateTypes() {
        LOG.info("Retrieving RejectDuplicateSet<Type> ...");
        RejectDuplicateSet<Type> types = new RejectDuplicateSet<Type> ();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            List<ConceptMap> answers = tx.execute(Graql.parse("match $x sub thing; get;").asGet()).get();
            for (ConceptMap answer : answers) {
                types.add(new Type(answer.get("x").asSchemaConcept()));
            }
        }
        LOG.info("...validating RejectDuplicateSet<Type> ");
        types.validate();
        return types;
    }

    RejectDuplicateSet<Type> createAndValidateRoles() {
        LOG.info("Retrieving roles...");
        RejectDuplicateSet<Type>  roles = new RejectDuplicateSet<Type> ();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            List<ConceptMap> answers = tx.execute(Graql.parse("match $x sub role; get;").asGet()).get();
            for (ConceptMap answer : answers) {
                roles.add(new Type(answer.get("x").asSchemaConcept()));
            }
        }
        LOG.info("...validating roles");
        roles.validate();
        return roles;
    }

    Sub createAndValidateSub(RejectDuplicateSet<Type> types) {
        LOG.info("Constructing Sub...");
        Sub sub = new Sub();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type child : types) {
                for (Type parent : types) {
                    // TODO we reject transitive sub using sub! but this is broken
//                    GraqlGet query = Graql.parse(String.format("match $child ype %s; $parent type %s; $child sub! $parent; $child != $parent; get;", child, parent)).asGet();
//                    boolean trueInGrakn = ask(tx, query);

                    // TODO replace concept API  when we can
                    boolean trueInGrakn = false;
                    if (!child.equals(parent) && !child.label().equals(META_TYPES.THING.getName())) {
                        SchemaConcept.Remote childType = tx.getSchemaConcept(Label.of(child.label()));
                        trueInGrakn = childType.sup().label().toString().equals(parent.label());
//                                .anyMatch(superType -> superType.label().toString().equals(parent.label()));
                    }

                    if (trueInGrakn) {
                        sub.add(new Pair<>(child, parent));
                    }
                }
            }
        }
        LOG.info("..validating Sub");
        sub.validate();
        return sub;
    }

    TransitiveSub createAndValidateTransitiveSubWithoutIdentity(Sub sub) {
        LOG.info("Constructing Transitive Sub...");
        TransitiveSub graknTransitiveSub = new TransitiveSub();

        try (GraknClient.Transaction tx = session.transaction().write()) {
            for (Pair<Type, Type> sub1 : sub) {
                for (Pair<Type, Type> sub2 : sub) {
                    // don't include (x,x) in the transitive sub closure
                    // this is because if we do end up with (x,x) in the transitive closure, then we know there is a loop
                    if (!sub1.first().equals(sub2.second())) {
                        GraqlGet query = Graql.parse(String.format("match $x type %s; $y type %s; $x sub $y; get;", sub1.first(), sub2.second())).asGet();
                        boolean trueInGrakn = ask(tx, query);
                        if (trueInGrakn) {
                            graknTransitiveSub.add(new Pair<>(sub1.first(), sub2.second()));
                        }
                    }
                }
            }
        }
        LOG.info("...validating Transitive Sub...");
        graknTransitiveSub.validate();
        return graknTransitiveSub;
    }

    RejectDuplicateSet<Type> createEntityTypes(TransitiveSub transitiveSub) {
        LOG.info("Constructing entity RejectDuplicateSet<Type>  set");
        RejectDuplicateSet<Type>  entityTypes = new RejectDuplicateSet<Type> ();
        for (Pair<Type, Type> sub : transitiveSub) {
            if (sub.second().label().equals("entity")) {
                entityTypes.add(sub.first());
            }
        }
        // TODO validate against Grakn that these are agreed to be entity RejectDuplicateSet<Type> 
        return entityTypes;
    }

    RejectDuplicateSet<Type> createRelationTypes(TransitiveSub transitiveSub) {
        LOG.info("Constructing relation RejectDuplicateSet<Type>  set");
        RejectDuplicateSet<Type>  entityTypes = new RejectDuplicateSet<Type>();
        for (Pair<Type, Type> sub : transitiveSub) {
            if (sub.second().label().equals("relation")) {
                entityTypes.add(sub.first());
            }
        }
        // TODO validate against Grakn that these are agreed to be relation RejectDuplicateSet<Type> 
        return entityTypes;
    }

    RejectDuplicateSet<Type> createAttributeTypes(TransitiveSub transitiveSub) {
        LOG.info("Constructing attribute RejectDuplicateSet<Type>  set");
        RejectDuplicateSet<Type>  entityTypes = new RejectDuplicateSet<Type> ();
        for (Pair<Type, Type> sub : transitiveSub) {
            if (sub.second().label().equals("attribute")) {
                entityTypes.add(sub.first());
            }
        }
        // TODO validate against Grakn that these are agreed to be attribute RejectDuplicateSet<Type> 
        return entityTypes;
    }

    Has createAndValidateHas(RejectDuplicateSet<Type> types, RejectDuplicateSet<Type> attributes) {
        LOG.info("Constructing Has set...");
        Has has = new Has();

        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type type : types) {
                for (Type attribute : attributes) {
                    // TODO - how to verify that the `has` is not inherited?
                    GraqlGet query = Graql.parse(String.format("match $owner type %s; $owner has %s; get;", type, attribute)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        has.add(new Pair<>(type, attribute));
                    }
                }
            }
        }

        LOG.info("...validating Has set");
        has.validate();
        return has;
    }

    Has createAndValidateKey(RejectDuplicateSet<Type> types, RejectDuplicateSet<Type> attributes, Has has) {
        LOG.info("Constructing Key set...");
        Has key = new Has();

        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type type : types) {
                for (Type attribute : attributes) {
                    // TODO - how to verify that the `key` is not inherited?
                    GraqlGet query = Graql.parse(String.format("match $owner type %s; $owner key %s; get;", type, attribute)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        key.add(new Pair<>(type, attribute));
                    }
                }
            }
        }

        LOG.info("...validating Key set");
        key.validate();

        // also validate key is a subset of has
        for (Pair<Type, Type> keyship : key) {
            if (!has.contains(keyship)) {
                throw IntegrityException.keyshipNotSubsetOfOwnership(keyship.first(), keyship.second());
            }
        }

        return key;
    }


    private Relates createAndValidateRelates(RejectDuplicateSet<Type> relations, RejectDuplicateSet<Type> roles) {
        LOG.info("Constructing Relates set...");
        Relates relates = new Relates();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type relation : relations) {
                for (Type role : roles) {
                    GraqlGet query = Graql.parse(String.format("match $type type %s; $type relates %s; get;", relation, role)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        relates.add(new Pair<>(relation, role));
                    }
                }
            }
        }

        LOG.info("...validating Relates set");
        relates.validate();

        // also validate that every relation has at least one role
        for (Type relation : relations) {
            boolean found = false;
            for (Pair<Type, Type> relatesRole : relates) {
                if (relatesRole.first().equals(relation)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                throw IntegrityException.relationWithoutRole(relation);
            }
        }
        return relates;
    }

    private Plays createAndValidatePlays(RejectDuplicateSet<Type> types, RejectDuplicateSet<Type> roles) {
        LOG.info("Constructing Relates set...");
        Plays plays = new Plays();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type relation : types) {
                for (Type role : roles) {
                    GraqlGet query = Graql.parse(String.format("match $type relates %s; $type plays %s; get;", relation, role)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        plays.add(new Pair<>(relation, role));
                    }
                }
            }
        }

        LOG.info("...validating Relates set");
        plays.validate();
        return plays;
    }

    private RejectDuplicateSet<Type> createAndValidateAbstractTypes(RejectDuplicateSet<Type> types) {
        LOG.info("Constructing Abstract set...");

        RejectDuplicateSet<Type> abstractTypes = new RejectDuplicateSet<Type>();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type type : types) {
                GraqlGet query = Graql.parse(String.format("match $owner type %s; $type abstract; get;", type)).asGet();
                boolean trueInGrakn = ask(tx, query);
                if (trueInGrakn) {
                    abstractTypes.add(type);
                }
            }
        }

        LOG.info("Validating Abstract set");
        abstractTypes.validate();
        return abstractTypes;
    }

    private boolean ask(GraknClient.Transaction tx, GraqlGet query) {
        List<ConceptMap> answer = tx.execute(query).get();
        return answer.size() == 1;
    }


    /*

     Outline:

     Goal: given a keyspace, verify basic integrity checks are preserved, building up from very low level structures


     Schema:
       * create sets:
         * Type
         * sub
         * transitive closure of sub, sub_trans
         * Type_attr, subset of type with (t, attribute) in sub_trans -- plus Type_entity and Type_relation
         * has: (Type, Type_attr)
         * key: (Type, Type_attr)
         * plays: (Type, Role)
         * relates: (Type_relation, Role)
         * abstract: Type
       * functions (?)
         * label, valuetype, regex

       *The goal is to create and verify these from the simplest building blocks, asking every possible combination at each
       step to create a valid pair for a set. The sets are then created and checked for validity.

       * As we build up the sets, each pair must be confirmed by Grakn, then the resulting relations are checked for logical integrity

     Data:
       * create sets:
         * Instances
         * isa
         * rel
         * has_data
         * key_data
       * functions:
         * id
         * val


      After building these (correct) sets, we use them to perform validation according to the conditions
      of validity for a data and a schema


     */

}
