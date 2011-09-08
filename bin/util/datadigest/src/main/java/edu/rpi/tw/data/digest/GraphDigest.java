package edu.rpi.tw.data.digest;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.openrdf.model.BNode;
import org.openrdf.model.Literal;
import org.openrdf.model.Resource;
import org.openrdf.model.Statement;
import org.openrdf.model.URI;
import org.openrdf.model.Value;
import org.openrdf.repository.Repository;
import org.openrdf.repository.RepositoryConnection;
import org.openrdf.repository.RepositoryException;
import org.openrdf.repository.RepositoryResult;
import org.openrdf.repository.sail.SailRepository;
import org.openrdf.rio.RDFFormat;
import org.openrdf.rio.RDFParseException;
import org.openrdf.sail.memory.MemoryStore;

/**
 * Compute the graph digest of an RDF graph.
 *
 */
public class GraphDigest {
    private String algorithm = "sha";
    private BigInteger total = BigInteger.ZERO;
    
    public GraphDigest(String algorithm) throws NoSuchAlgorithmException {
        this.algorithm = algorithm;
        MessageDigest.getInstance(algorithm);
    }

    public GraphDigest() throws NoSuchAlgorithmException {
        MessageDigest.getInstance(algorithm);
    }

    public String serializeValue(Value val) {
        String result = val.stringValue();
        if (val instanceof URI)
            result = "<"+result+">";
        else if (val instanceof BNode)
            result = "["+result+"]";
        else if (val instanceof Literal) {
            Literal lit = (Literal) val;
            String language = lit.getLanguage();
            if (language == null) language = "";
            else language = "@"+language;
            URI datatype = lit.getDatatype();
            String datatypeString = "";
            if (datatype != null) datatypeString = "^^<"+datatype.stringValue()+">";
            result = "\""+result+"\""+language+datatypeString;
        }
        return result;
    }
    
    public void update(Repository rep, boolean includeInferred, boolean quads, Resource... contexts) 
            throws RepositoryException {
        RepositoryConnection conn = null;
        try {
            conn = rep.getConnection();
            RepositoryResult<Statement> statements = conn.getStatements(null, null, null, quads, contexts);
            for (Statement s : statements.asList()) {
                try {
                    MessageDigest digest = MessageDigest.getInstance(algorithm);
                    String subject = serializeValue(s.getSubject());
                    String predicate = serializeValue(s.getPredicate());
                    String object = serializeValue(s.getObject());
                    String statement = subject +" "+predicate+" "+object;
                    if (quads) {
                        String context = serializeValue(s.getContext());
                        statement = statement+ " "+context;
                    }
                    digest.update(statement.getBytes());
                    byte[] bytes = digest.digest();
                    BigInteger bigInt = new BigInteger(1, bytes);
                    total = total.add(bigInt);
                } catch (NoSuchAlgorithmException e) {
                    // This should have already been checked by the constructor.
                }
            }
        } finally {
            if (conn != null && conn.isOpen())
                conn.close();
        }
    }
    
    public BigInteger digest() {
        return total;
    }
    
    public static BigInteger fileDigest(File file) throws NoSuchAlgorithmException, IOException {
        MessageDigest digest = MessageDigest.getInstance("sha");
        FileChannel channel = new FileInputStream(file).getChannel();
        ByteBuffer buffer = ByteBuffer.allocate((int) channel.size());
        channel.read(buffer);
        return new BigInteger(1,digest.digest(buffer.array()));
    }
    
    public static void main( String[] args ) throws NoSuchAlgorithmException, RepositoryException, RDFParseException, IOException {
        for (String f : args) {
            System.out.println(f);
            System.out.println("Message Digest is:\t"+fileDigest(new File(f)).toString(16));
            GraphDigest digest = new GraphDigest();
            Repository myRepository = new SailRepository(new MemoryStore());
            myRepository.initialize();
            RepositoryConnection conn = myRepository.getConnection();
            conn.add(new File(args[0]), "#", RDFFormat.forFileName(f));
            conn.commit();
            conn.close();
            digest.update(myRepository, false, false);
            System.out.println("Graph Digest is:\t"+digest.digest().toString(16));
        }
    }
}
